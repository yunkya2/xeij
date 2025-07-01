#========================================================================================
#  drawingmode.pl
#  Copyright (C) 2003-2025 Makoto Kamada
#
#  This file is part of the XEiJ (X68000 Emulator in Java).
#  You can use, modify and redistribute the XEiJ if the conditions are met.
#  Read the XEiJ License for more details.
#  https://stdkmd.net/xeij/
#========================================================================================



#----------------------------------------------------------------------------------------
#
#  DrawingMode.javaを作る
#
#----------------------------------------------------------------------------------------

use strict;  #厳密な文法に従う
use warnings;  #警告を表示する
use utf8;  #UTF-8で記述する
binmode STDOUT, ':encoding(cp932)';  #標準出力はcp932(Shift_JISでは'～'(\uff5e)が使えない)
binmode STDERR, ':encoding(cp932)';  #標準エラー出力はcp932(Shift_JISでは'～'(\uff5e)が使えない)

$| = 1;



my $JAVA_HEADER = <<'XXX';
//========================================================================================
//  DrawingMode.java
//    en:Drawing mode -- It superimposes a raster of the sprite screen, the text screen and the graphic screen according to the drawing mode.
//    ja:描画モード -- 描画モードに従って1ラスタ分のスプライト画面、テキスト画面およびグラフィック画面を重ね合わせます。
//  Copyright (C) 2003-2025 Makoto Kamada
//
//  This file is part of the XEiJ (X68000 Emulator in Java).
//  You can use, modify and redistribute the XEiJ if the conditions are met.
//  Read the XEiJ License for more details.
//  https://stdkmd.net/xeij/
//========================================================================================
XXX



#========================================================================================
#基本モード
#
my %KEY_TEXT = (
  N  => '表示画面なし',
  S  => 'スプライト',
  s  => 'スプライト(OFF)',
  T  => 'テキスト',
  t  => 'テキスト(OFF)',
  E1 => '512ドット16色1プレーン',  #1番目はON、2番目と3番目と4番目はOFF
  E2 => '512ドット16色2プレーン',  #2番目はON、3番目と4番目はOFF。1番目はOFFのときパレット0とみなす
  E3 => '512ドット16色3プレーン',  #3番目はON、4番目はOFF。1番目と2番目はOFFのときパレット0とみなす
  E4 => '512ドット16色4プレーン',  #4番目はON。1番目と2番目と3番目はOFFのときパレット0とみなす
  F1 => '512ドット256色1プレーン',  #1番目はON、2番目はOFF
  F2 => '512ドット256色2プレーン',  #2番目はON。1番目はOFFのときパレット0とみなす
  G  => '512ドット65536色1プレーン',  #1番目はON
  H  => '1024ドット16色1プレーン',  #1番目はON
  I  => '1024ドット256色1プレーン',  #1番目はON
  J  => '1024ドット65536色1プレーン'  #1番目はON
  );

#キーワード
#
#  ● N 表示画面なし
#
#  ● S スプライト
#       ← St スプライト＞テキスト(OFF)
#       ← tS テキスト(OFF)＞スプライト
#
#     s スプライト(OFF) → t テキスト(OFF)
#
#  ● T テキスト
#       ← sT スプライト(OFF)＞テキスト
#       ← Ts テキスト＞スプライト(OFF)
#
#  ○ t テキスト(OFF)
#       ← s スプライト(OFF)
#       ← st スプライト(OFF)＞テキスト(OFF)
#       ← ts テキスト(OFF)＞スプライト(OFF)
#
#  ● ST スプライト＞テキスト
#
#     St スプライト＞テキスト(OFF) → S スプライト
#
#     sT スプライト(OFF)＞テキスト → T テキスト
#
#     st スプライト(OFF)＞テキスト(OFF) → t テキスト(OFF)
#
#  ● TS テキスト＞スプライト
#
#     Ts テキスト＞スプライト(OFF) → T テキスト
#
#     tS テキスト(OFF)＞スプライト → S スプライト
#
#     ts テキスト(OFF)＞スプライト(OFF) → t テキスト(OFF)
#
#  ● G グラフィック
#       ← sG スプライト(OFF)＞グラフィック
#       ← tG テキスト(OFF)＞グラフィック
#       ← stG スプライト(OFF)＞テキスト(OFF)＞グラフィック
#       ← tsG テキスト(OFF)＞スプライト(OFF)＞グラフィック
#
#  ● GS グラフィック＞スプライト
#       ← GSt グラフィック＞スプライト＞テキスト(OFF)
#       ← GtS グラフィック＞テキスト(OFF)＞スプライト
#       ← tGS テキスト(OFF)＞グラフィック＞スプライト
#
#     Gs グラフィック＞スプライト(OFF) → Gt グラフィック＞テキスト(OFF)
#
#  ● SG スプライト＞グラフィック
#       ← StG スプライト＞テキスト(OFF)＞グラフィック
#       ← tSG テキスト(OFF)＞スプライト＞グラフィック
#
#     sG スプライト(OFF)＞グラフィック → G グラフィック
#
#  ● GT グラフィック＞テキスト
#       ← GTs グラフィック＞テキスト＞スプライト(OFF)
#       ← GsT グラフィック＞スプライト(OFF)＞テキスト
#       ← sGT スプライト(OFF)＞グラフィック＞テキスト
#
#  ● Gt グラフィック＞テキスト(OFF)
#       ← Gs グラフィック＞スプライト(OFF)
#       ← Gst グラフィック＞スプライト(OFF)＞テキスト(OFF)
#       ← sGt スプライト(OFF)＞グラフィック＞テキスト(OFF)
#       ← Gts グラフィック＞テキスト(OFF)＞スプライト(OFF)
#       ← tGs テキスト(OFF)＞グラフィック＞スプライト(OFF)
#
#  ● TG テキスト＞グラフィック
#       ← sTG スプライト(OFF)＞テキスト＞グラフィック
#       ← TsG テキスト＞スプライト(OFF)＞グラフィック
#
#     tG テキスト(OFF)＞グラフィック → G グラフィック
#
#  ● GST グラフィック＞スプライト＞テキスト
#
#     GSt グラフィック＞スプライト＞テキスト(OFF) → GS グラフィック＞スプライト
#
#     GsT グラフィック＞スプライト(OFF)＞テキスト → GT グラフィック＞テキスト
#
#     Gst グラフィック＞スプライト(OFF)＞テキスト(OFF) → Gt グラフィック＞テキスト(OFF)
#
#  ● SGT スプライト＞グラフィック＞テキスト
#
#  ● SGt スプライト＞グラフィック＞テキスト(OFF)
#
#     sGT スプライト(OFF)＞グラフィック＞テキスト → GT グラフィック＞テキスト
#
#     sGt スプライト(OFF)＞グラフィック＞テキスト(OFF) → Gt グラフィック＞テキスト(OFF)
#
#  ● STG スプライト＞テキスト＞グラフィック
#
#     StG スプライト＞テキスト(OFF)＞グラフィック → SG スプライト＞グラフィック
#
#     sTG スプライト(OFF)＞テキスト＞グラフィック → TG テキスト＞グラフィック
#
#     stG スプライト(OFF)＞テキスト(OFF)＞グラフィック → G グラフィック
#
#  ● GTS グラフィック＞テキスト＞スプライト
#
#     GTs グラフィック＞テキスト＞スプライト(OFF) → GT グラフィック＞テキスト
#
#     GtS グラフィック＞テキスト(OFF)＞スプライト → GS グラフィック＞スプライト
# 
#     Gts グラフィック＞テキスト(OFF)＞スプライト(OFF) → Gt グラフィック＞テキスト(OFF)
#
#  ● TGS テキスト＞グラフィック＞スプライト
#
#  ● TGs テキスト＞グラフィック＞スプライト(OFF)
#
#     tGS テキスト(OFF)＞グラフィック＞スプライト → GS グラフィック＞スプライト
#
#     tGs テキスト(OFF)＞グラフィック＞スプライト(OFF) → Gt グラフィック＞テキスト(OFF)
#
#  ● TSG テキスト＞スプライト＞グラフィック
#
#     TsG テキスト＞スプライト(OFF)＞グラフィック → TG テキスト＞グラフィック
#
#     tSG テキスト(OFF)＞スプライト＞グラフィック → SG スプライト＞グラフィック
#
#     tsG テキスト(OFF)＞スプライト(OFF)＞グラフィック → G グラフィック
#
my @KEYWORD = (
  map {
    my ($e1, $e2, $e3, $e4, $f1, $f2, $g, $h, $i, $j) = ($_, $_, $_, $_, $_, $_, $_, $_, $_, $_);
    $e1 =~ s/G/E1/;
    $e2 =~ s/G/E2/;
    $e3 =~ s/G/E3/;
    $e4 =~ s/G/E4/;
    $f1 =~ s/G/F1/;
    $f2 =~ s/G/F2/;
    $g =~ s/G/G/;
    $h =~ s/G/H/;
    $i =~ s/G/I/;
    $j =~ s/G/J/;
    $g =~ /G/ ? ($e1, $e2, $e3, $e4, $f1, $f2, $g, $h, $i, $j) : $g  #GをE1,E2,E3,E4,F1,F2,G,H,I,Jに分ける
    }
  qw(N
     S
     T
     ST
     TS
     G
     GS
     SG
     GT
     Gt
     TG
     GST
     SGT
     SGt
     STG
     GTS
     TGS
     TGs
     TSG
     )
    );
#print join (', ', @KEYWORD) . "\n";



#================================================================================
#拡張モード
#  1行の概要は要点だけなので実際の動作はコードの注釈で確認すること
#  512ドット65536色と1024ドットのとき1番目と2番目を混ぜるGは未対応
#  A,X以外の拡張モードは非対応
my %X_TEXT = (
  #X  拡張あり
  # W  特殊プライオリティ
  #    GとTは動作に影響しない
  #    0でない1番目がないときパレット0とみなす
  #  C  カラーで領域指定
  XWC => '優先順位に関わらず0でない1番目のパレットを偶数化(65536色は奇数化)したパレットのカラーが奇数のとき0でない1番目のパレットのカラーだけ表示する',
  #  P  パレットで領域指定
  XWP => '優先順位に関わらず1番目のパレットが3以上の奇数のときそれを偶数化したパレットのカラーだけ表示する',
  # H  半透明
  #    Gは2番目がOFFでもONとみなす
  #    0でない1番目がないときパレット0とみなす
  #  C  カラーで領域指定
  XHCT => '0でない1番目のパレットを偶数化(65536色は奇数化)したパレットのカラーが奇数のとき0でない1番目のカラーと奥のスプライト・テキストのカラーを混ぜる',
  XHCG => '0でない1番目のパレットを偶数化したパレットのカラーが奇数のときそれと2番目のパレットを奇数化したパレットのカラーを混ぜる',
  XHCGT => '0でない1番目のパレットを偶数化したパレットのカラーが奇数のときそれと2番目のパレットを奇数化したパレットのカラーを混ぜてさらに奥のスプライト・テキストのカラーを混ぜる',
  #  P  パレットで領域指定
  XHPT => '1番目のパレットが3以上の奇数のときそれを偶数化したパレットのカラーと奥のスプライト・テキストのカラーを混ぜる',
  XHPG => '1番目のパレットが3以上の奇数のときそれを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜる',
  XHPGT => '1番目のパレットが3以上の奇数のときそれを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜてさらに奥のスプライト・テキストのカラーを混ぜる',
  #A  テキストパレット0と半透明
  A => 'グラフィックカラーとテキストパレット0のカラーを混ぜる'
  );



#================================================================================
sub make_regs {
  my ($keyword, $xword) = @_;
  my $reg1 = 0x0000;
  my $reg2 = 0x00e4;
  my $reg3 = 0x0000;
  $keyword =~ s/N//;
  $keyword =~ /[Ss]/ or $keyword = 's' . $keyword;  #Sまたはsがないとき先頭にsを入れる
  $keyword =~ /[Tt]/ or $keyword =~ s/(?<=[Ss])/t/;  #TまたはtがないときSまたはsの直後にtを入れる
  $keyword =~ /S/ and $reg3 |= 0x0040;
  $keyword =~ /T/ and $reg3 |= 0x0020;
  if ($keyword =~ /E/) {  #512ドット16色
    #$reg1 |= 0x0000;
    $reg3 |= ($keyword =~ /E1/ ? 0x0001 :  #512ドット16色1プレーン
              $keyword =~ /E2/ ? 0x0003 :  #512ドット16色2プレーン
              $keyword =~ /E3/ ? 0x0007 :  #512ドット16色3プレーン
              $keyword =~ /E4/ ? 0x000f :  #512ドット16色4プレーン
              die $keyword);
  } elsif ($keyword =~ /F/) {  #512ドット256色
    $reg1 |= 0x0001;
    $reg3 |= ($keyword =~ /F1/ ? 0x0003 :  #512ドット256色1プレーン
              $keyword =~ /F2/ ? 0x000f :  #512ドット256色2プレーン
              die $keyword);
  } elsif ($keyword =~ /G/) {  #512ドット65536色
    $reg1 |= 0x0003;
    $reg3 |= 0x000f;
  } elsif ($keyword =~ /H/) {  #1024ドット16色
    $reg1 |= 0x0004;
    $reg3 |= 0x0010;
  } elsif ($keyword =~ /I/) {  #1024ドット256色
    $reg1 |= 0x0005;
    $reg3 |= 0x0010;
  } elsif ($keyword =~ /J/) {  #1024ドット65536色
    $reg1 |= 0x0007;
    $reg3 |= 0x0010;
  }
  $keyword =~ s/(?:E1|E2|E3|E4|F1|F2|G|H|I|J)/G/;
  $keyword =~ /G/ or $keyword .= 'g';  #Gがないとき末尾にgを入れる
  $keyword =~ tr/a-z/A-Z/;
  $reg2 |= ($keyword eq 'STG' ? 0b00_01_10 << 8 :
            $keyword eq 'SGT' ? 0b00_10_01 << 8 :
            $keyword eq 'TSG' ? 0b01_00_10 << 8 :
            $keyword eq 'TGS' ? 0b10_00_01 << 8 :
            $keyword eq 'GST' ? 0b01_10_00 << 8 :
            $keyword eq 'GTS' ? 0b10_01_00 << 8 :
            die $keyword);
  $xword =~ /A/ and $reg3 |= 0x4000;
  $xword =~ /X/ and $reg3 |= 0x1000;
  #$xword =~ /W/ and $reg3 |= 0x0000;
  $xword =~ /H/ and $reg3 |= 0x0800;
  #$xword =~ /C/ and $reg3 |= 0x0000;
  $xword =~ /P/ and $reg3 |= 0x0400;
  $xword =~ /G/ and $reg3 |= 0x0200;
  $xword =~ /T/ and $reg3 |= 0x0100;
  sprintf '$%04X,$%02Xxx,$%04X', $reg1, $reg2 >> 8, $reg3;
}



#================================================================================
#中間コード
#  spp()       スプライトパレット
#  spc(p)      スプライトパレットpのカラー
#  spo(p)      スプライトパレットpのARGB
#  txp()       テキストパレット
#  tpc(p)      テキストパレットpのカラー
#  tpo(p)      テキストパレットpのARGB
#  e1p()       512ドット16色で1番目のパレット
#  e2p()       512ドット16色で2番目のパレット
#  e2q()       512ドット16色で2番目(ONとみなす)のパレット
#  e3p()       512ドット16色で3番目のパレット
#  e4p()       512ドット16色で4番目のパレット
#  epc(p)      512ドット16色でパレットpのカラー
#  epo(p)      512ドット16色でパレットpのARGB
#  f1p()       512ドット256色で1番目のパレット
#  f2p()       512ドット256色で2番目のパレット
#  f2q()       512ドット256色で2番目(ONとみなす)のパレット
#  fpc(p)      512ドット256色でパレットpのカラー
#  fpo(p)      512ドット256色でパレットpのARGB
#  g1p()       512ドット65536色で1番目のパレット
#  gpc(p,q)    512ドット65536色でパレットp==qのカラー
#  gpo(p)      512ドット65536色でパレットpのARGB
#  h1p()       1024ドット16色で1番目のパレット
#  hpc(p)      1024ドット16色でパレットpのカラー
#  hpo(p)      1024ドット16色でパレットpのARGB
#  i1p()       1024ドット256色で1番目のパレット
#  ipc(p)      1024ドット256色でパレットpのカラー
#  ipo(p)      1024ドット256色でパレットpのARGB
#  j1p()       1024ドット65536色で1番目のパレット
#  jpc(p,q)    1024ドット65536色でパレットp==qのカラー
#  jpo(p)      1024ドット65536色でパレットpのARGB
#  ls1(p)      パレットpの下位1ビット。p&1
#  ls4(p)      パレットpの下位4ビット。p&15
#  tev(p)      パレットpを偶数化したパレット。p&-2
#  tod(p)      パレットpを奇数化したパレット。p|1
#  mix(c1,c2)  カラーc1とカラーc2を混ぜたカラー。g=g1+g2>>1,r=r1+r2>>1,b=b1+b2>>1,i=i2



#================================================================================
#パス1
#  基本モードと拡張モードから手順と中間コード1を作る
sub pass1 {
  my ($indent, $keyword, $mode) = @_;
  my $xword = $mode->{'xword'};  #拡張ワード
  my $encode = $mode->{'encode'};  #0=手順,1=コード

  my $pt = ($keyword =~ /(?:E)/ ? 'e' :  #512ドット16色
            $keyword =~ /(?:F)/ ? 'f' :  #512ドット256色
            $keyword =~ /(?:G)/ ? 'g' :  #512ドット65536色
            $keyword =~ /(?:H)/ ? 'h' :  #1024ドット16色
            $keyword =~ /(?:I)/ ? 'i' :  #1024ドット256色
            $keyword =~ /(?:J)/ ? 'j' :  #1024ドット65536色
            '');
  my $dp = $pt eq 'g' || $pt eq 'j';  #gpc(p)とjpc(p)をgpc(p,p)とjpc(p,p)にする

  my @out = ();

  if ($xword eq 'A') {  #グラフィックカラーとテキストパレット0のカラーを混ぜる
    if ($keyword =~ /(?:E1|F1|G|H|I|J)/) {  #グラフィック1プレーン。1番目はON、2番目と3番目と4番目はOFF
      push @out, $encode ? ($dp ?
                            "mix(${pt}pc(${pt}1p(),${pt}1p()),tpc(0))" :
                            "mix(${pt}pc(${pt}1p()),tpc(0))") : "${indent}1番目のカラーとテキストパレット0のカラーを混ぜたカラー(0は黒)\n";
    } elsif ($keyword =~ /(?:E2|F2)/) {  #グラフィック2プレーン。2番目はON、3番目と4番目はOFF。1番目はOFFのときパレット0とみなす
      push @out, $encode ? "(" : "";
      push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
      push @out, $encode ? "?" : "";
      push @out, $encode ? ($dp ?
                            "mix(${pt}pc(${pt}1p(),${pt}1p()),tpc(0))" :
                            "mix(${pt}pc(${pt}1p()),tpc(0))") : "${indent}  1番目のカラーとテキストパレット0のカラーを混ぜたカラー(0は黒)\n";
      push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
      push @out, $encode ? ($dp ?
                            "mix(${pt}pc(${pt}2p(),${pt}2p()),tpc(0))" :
                            "mix(${pt}pc(${pt}2p()),tpc(0))") : "${indent}  2番目のカラーとテキストパレット0のカラーを混ぜたカラー(0は黒)\n";
      push @out, $encode ? ")" : "";
    } elsif ($keyword =~ /(?:E3)/) {  #グラフィック3プレーン。3番目はON、4番目はOFF。1番目と2番目はOFFのときパレット0とみなす
      push @out, $encode ? "(" : "";
      push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
      push @out, $encode ? "?" : "";
      push @out, $encode ? ($dp ?
                            "mix(${pt}pc(${pt}1p(),${pt}1p()),tpc(0))" :
                            "mix(${pt}pc(${pt}1p()),tpc(0))") : "${indent}  1番目のカラーとテキストパレット0のカラーを混ぜたカラー(0は黒)\n";
      push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
      push @out, $encode ? "(" : "";
      push @out, $encode ? "${pt}2p()!=0" : "${indent}  2番目のパレットが0でないとき\n";
      push @out, $encode ? "?" : "";
      push @out, $encode ? ($dp ?
                            "mix(${pt}pc(${pt}2p(),${pt}2p()),tpc(0))" :
                            "mix(${pt}pc(${pt}2p()),tpc(0))") : "${indent}    2番目のカラーとテキストパレット0のカラーを混ぜたカラー(0は黒)\n";
      push @out, $encode ? ":" : "${indent}  さもなくば(2番目のパレットが0のとき)\n";
      push @out, $encode ? ($dp ?
                            "mix(${pt}pc(${pt}3p(),${pt}3p()),tpc(0))" :
                            "mix(${pt}pc(${pt}3p()),tpc(0))") : "${indent}    3番目のカラーとテキストパレット0のカラーを混ぜたカラー(0は黒)\n";
      push @out, $encode ? ")" : "";
      push @out, $encode ? ")" : "";
    } elsif ($keyword =~ /(?:E4)/) {  #グラフィック4プレーン。4番目はON。1番目と2番目と3番目はOFFのときパレット0とみなす
      push @out, $encode ? "(" : "";
      push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
      push @out, $encode ? "?" : "";
      push @out, $encode ? ($dp ?
                            "mix(${pt}pc(${pt}1p(),${pt}1p()),tpc(0))" :
                            "mix(${pt}pc(${pt}1p()),tpc(0))") : "${indent}  1番目のカラーとテキストパレット0のカラーを混ぜたカラー(0は黒)\n";
      push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
      push @out, $encode ? "(" : "";
      push @out, $encode ? "${pt}2p()!=0" : "${indent}  2番目のパレットが0でないとき\n";
      push @out, $encode ? "?" : "";
      push @out, $encode ? ($dp ?
                            "mix(${pt}pc(${pt}2p(),${pt}2p()),tpc(0))" :
                            "mix(${pt}pc(${pt}2p()),tpc(0))") : "${indent}    2番目のカラーとテキストパレット0のカラーを混ぜたカラー(0は黒)\n";
      push @out, $encode ? ":" : "${indent}  さもなくば(2番目のパレットが0のとき)\n";
      push @out, $encode ? "(" : "";
      push @out, $encode ? "${pt}3p()!=0" : "${indent}    3番目のパレットが0でないとき\n";
      push @out, $encode ? "?" : "";
      push @out, $encode ? ($dp ?
                            "mix(${pt}pc(${pt}3p(),${pt}3p()),tpc(0))" :
                            "mix(${pt}pc(${pt}3p()),tpc(0))") : "${indent}      3番目のカラーとテキストパレット0のカラーを混ぜたカラー(0は黒)\n";
      push @out, $encode ? ":" : "${indent}    さもなくば(3番目のパレットが0のとき)\n";
      push @out, $encode ? ($dp ?
                            "mix(${pt}pc(${pt}4p(),${pt}4p()),tpc(0))" :
                            "mix(${pt}pc(${pt}4p()),tpc(0))") : "${indent}      4番目のカラーとテキストパレット0のカラーを混ぜたカラー(0は黒)\n";
      push @out, $encode ? ")" : "";
      push @out, $encode ? ")" : "";
      push @out, $encode ? ")" : "";
    } else {
      push @out, $encode ? "0" : "${indent}カラー0(黒)\n";  #グラフィックがOFFのときは表示なし。テキストパレット0が黒でなくても黒になる
    }
    return @out;
  }

  if ($keyword =~ /(?:E1|E2|E3|E4|F1|F2|G|H|I|J)/) {  #グラフィックが1プレーン以上ある
    my $ahead = $`;  #グラフィックの手前にある画面
    my $g = $&;  #グラフィック
    my $behind = $';  #グラフィックの奥にある画面

    if ($xword eq 'XWC') {  #優先順位に関わらず0でない1番目のパレットを偶数化(65536色は奇数化)したパレットのカラーが奇数のとき0でない1番目のパレットのカラーだけ表示する
      $mode->{'xword'} = '';
      if ($ahead eq '' && $behind eq '') {  #グラフィックのみ
        push @out, pass1 ("${indent}", $g, $mode);
      } elsif ($g =~ /(?:G|J)/) {  #65536色
        push @out, $encode ? "(" : "";
        push @out, $encode ? ($dp ?
                              "ls1(${pt}pc(tod(${pt}1p()),tod(${pt}1p())))!=0" :
                              "ls1(${pt}pc(tod(${pt}1p())))!=0") : "${indent}1番目のパレットを奇数化したパレットのカラーが奇数のとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? ($dp ?
                              "${pt}pc(${pt}1p(),${pt}1p())" :
                              "${pt}pc(${pt}1p())") : "${indent}  1番目のカラー(0は黒)\n";
        push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットを奇数化したパレットのカラーが偶数のとき)\n";
        push @out, pass1 ("${indent}  ", $keyword, $mode);
        push @out, $encode ? ")" : "";
      } elsif ($g =~ /(?:E1|F1|H|I)/) {  #グラフィック1プレーン。1番目はON、2番目と3番目と4番目はOFF
        push @out, $encode ? "(" : "";
        push @out, $encode ? ($dp ?
                              "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                              "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? ($dp ?
                              "${pt}pc(${pt}1p(),${pt}1p())" :
                              "${pt}pc(${pt}1p())") : "${indent}  1番目のカラー(0は黒)\n";
        push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
        push @out, pass1 ("${indent}  ", $keyword, $mode);
        push @out, $encode ? ")" : "";
      } elsif ($g =~ /(?:E2|F2)/) {  #グラフィック2プレーン。2番目はON、3番目と4番目はOFF。1番目はOFFのときパレット0とみなす
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
        push @out, $encode ? "?" : "";
        $mode->{'nonzero1st'}++;
        push @out, $encode ? "(" : "";
        push @out, $encode ? ($dp ?
                              "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                              "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}  1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? ($dp ?
                              "${pt}pc(${pt}1p(),${pt}1p())" :
                              "${pt}pc(${pt}1p())") : "${indent}    1番目のカラー(0は黒)\n";
        push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
        push @out, pass1 ("${indent}    ", $keyword, $mode);
        push @out, $encode ? ")" : "";
        $mode->{'nonzero1st'}--;
        push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
        $mode->{'zero1st'}++;
        $mode->{'even1st'}++;
        push @out, $encode ? "(" : "";
        push @out, $encode ? ($dp ?
                              "ls1(${pt}pc(tev(${pt}2p()),tev(${pt}2p())))!=0" :
                              "ls1(${pt}pc(tev(${pt}2p())))!=0") : "${indent}  2番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? ($dp ?
                              "${pt}pc(${pt}2p(),${pt}2p())" :
                              "${pt}pc(${pt}2p())") : "${indent}    2番目のカラー(0は黒)\n";
        push @out, $encode ? ":" : "${indent}  さもなくば(2番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
        push @out, pass1 ("${indent}    ", $keyword, $mode);
        push @out, $encode ? ")" : "";
        $mode->{'even1st'}--;
        $mode->{'zero1st'}--;
        push @out, $encode ? ")" : "";
      } elsif ($g =~ /(?:E3)/) {  #グラフィック3プレーン。3番目はON、4番目はOFF。1番目と2番目はOFFのときパレット0とみなす
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
        push @out, $encode ? "?" : "";
        $mode->{'nonzero1st'}++;
        push @out, $encode ? "(" : "";
        push @out, $encode ? ($dp ?
                              "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                              "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}  1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? ($dp ?
                              "${pt}pc(${pt}1p(),${pt}1p())" :
                              "${pt}pc(${pt}1p())") : "${indent}    1番目のカラー(0は黒)\n";
        push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
        push @out, pass1 ("${indent}    ", $keyword, $mode);
        push @out, $encode ? ")" : "";
        $mode->{'nonzero1st'}--;
        push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
        $mode->{'zero1st'}++;
        $mode->{'even1st'}++;
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${pt}2p()!=0" : "${indent}  2番目のパレットが0でないとき\n";
        push @out, $encode ? "?" : "";
        $mode->{'nonzero2nd'}++;
        push @out, $encode ? "(" : "";
        push @out, $encode ? ($dp ?
                              "ls1(${pt}pc(tev(${pt}2p()),tev(${pt}2p())))!=0" :
                              "ls1(${pt}pc(tev(${pt}2p())))!=0") : "${indent}    2番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? ($dp ?
                              "${pt}pc(${pt}2p(),${pt}2p())" :
                              "${pt}pc(${pt}2p())") : "${indent}      2番目のカラー(0は黒)\n";
        push @out, $encode ? ":" : "${indent}    さもなくば(2番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
        push @out, pass1 ("${indent}      ", $keyword, $mode);
        push @out, $encode ? ")" : "";
        $mode->{'nonzero2nd'}--;
        push @out, $encode ? ":" : "${indent}  さもなくば(2番目のパレットが0のとき)\n";
        $mode->{'zero2nd'}++;
        $mode->{'even2nd'}++;
        push @out, $encode ? "(" : "";
        push @out, $encode ? ($dp ?
                              "ls1(${pt}pc(tev(${pt}3p()),tev(${pt}3p())))!=0" :
                              "ls1(${pt}pc(tev(${pt}3p())))!=0") : "${indent}    3番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? ($dp ?
                              "${pt}pc(${pt}3p(),${pt}3p())" :
                              "${pt}pc(${pt}3p())") : "${indent}      3番目のカラー(0は黒)\n";
        push @out, $encode ? ":" : "${indent}    さもなくば(3番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
        push @out, pass1 ("${indent}      ", $keyword, $mode);
        push @out, $encode ? ")" : "";
        $mode->{'even2nd'}--;
        $mode->{'zero2nd'}--;
        push @out, $encode ? ")" : "";
        $mode->{'even1st'}--;
        $mode->{'zero1st'}--;
        push @out, $encode ? ")" : "";
      } elsif ($g =~ /(?:E4)/) {  #グラフィック4プレーン。4番目はON。1番目と2番目と3番目はOFFのときパレット0とみなす
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
        push @out, $encode ? "?" : "";
        $mode->{'nonzero1st'}++;
        push @out, $encode ? "(" : "";
        push @out, $encode ? ($dp ?
                              "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                              "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}  1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? ($dp ?
                              "${pt}pc(${pt}1p(),${pt}1p())" :
                              "${pt}pc(${pt}1p())") : "${indent}    1番目のカラー(0は黒)\n";
        push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
        push @out, pass1 ("${indent}    ", $keyword, $mode);
        push @out, $encode ? ")" : "";
        $mode->{'nonzero1st'}--;
        push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
        $mode->{'zero1st'}++;
        $mode->{'even1st'}++;
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${pt}2p()!=0" : "${indent}  2番目のパレットが0でないとき\n";
        push @out, $encode ? "?" : "";
        $mode->{'nonzero2nd'}++;
        push @out, $encode ? "(" : "";
        push @out, $encode ? ($dp ?
                              "ls1(${pt}pc(tev(${pt}2p()),tev(${pt}2p())))!=0" :
                              "ls1(${pt}pc(tev(${pt}2p())))!=0") : "${indent}    2番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? ($dp ?
                              "${pt}pc(${pt}2p(),${pt}2p())" :
                              "${pt}pc(${pt}2p())") : "${indent}      2番目のカラー(0は黒)\n";
        push @out, $encode ? ":" : "${indent}    さもなくば(2番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
        push @out, pass1 ("${indent}      ", $keyword, $mode);
        push @out, $encode ? ")" : "";
        $mode->{'nonzero2nd'}--;
        push @out, $encode ? ":" : "${indent}  さもなくば(2番目のパレットが0のとき)\n";
        $mode->{'zero2nd'}++;
        $mode->{'even2nd'}++;
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${pt}3p()!=0" : "${indent}    3番目のパレットが0でないとき\n";
        push @out, $encode ? "?" : "";
        $mode->{'nonzero3rd'}++;
        push @out, $encode ? "(" : "";
        push @out, $encode ? ($dp ?
                              "ls1(${pt}pc(tev(${pt}3p()),tev(${pt}3p())))!=0" :
                              "ls1(${pt}pc(tev(${pt}3p())))!=0") : "${indent}      3番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? ($dp ?
                              "${pt}pc(${pt}3p(),${pt}3p())" :
                              "${pt}pc(${pt}3p())") : "${indent}        3番目のカラー(0は黒)\n";
        push @out, $encode ? ":" : "${indent}      さもなくば(3番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
        push @out, pass1 ("${indent}        ", $keyword, $mode);
        push @out, $encode ? ")" : "";
        $mode->{'nonzero3rd'}--;
        push @out, $encode ? ":" : "${indent}    さもなくば(3番目のパレットが0のとき)\n";
        $mode->{'zero3rd'}++;
        $mode->{'even3rd'}++;
        push @out, $encode ? "(" : "";
        push @out, $encode ? ($dp ?
                              "ls1(${pt}pc(tev(${pt}4p()),tev(${pt}4p())))!=0" :
                              "ls1(${pt}pc(tev(${pt}4p())))!=0") : "${indent}      4番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? ($dp ?
                              "${pt}pc(${pt}4p(),${pt}4p())" :
                              "${pt}pc(${pt}4p())") : "${indent}        4番目のカラー(0は黒)\n";
        push @out, $encode ? ":" : "${indent}      さもなくば(4番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
        push @out, pass1 ("${indent}        ", $keyword, $mode);
        push @out, $encode ? ")" : "";
        $mode->{'even3rd'}--;
        $mode->{'zero3rd'}--;
        push @out, $encode ? ")" : "";
        $mode->{'even2nd'}--;
        $mode->{'zero2nd'}--;
        push @out, $encode ? ")" : "";
        $mode->{'even1st'}--;
        $mode->{'zero1st'}--;
        push @out, $encode ? ")" : "";
      } else {
        die $keyword;
      }
      $mode->{'xword'} = $xword;
      return @out;
    }

    if ($xword eq 'XWP') {  #優先順位に関わらず1番目のパレットが3以上の奇数のときそれを偶数化したパレットのカラーだけ表示する
      $mode->{'xword'} = '';
      push @out, $encode ? "(" : "";
      if (0) {
        push @out, $encode ? "${pt}1p()==0" : "${indent}1番目のパレットが0のとき\n";
        push @out, $encode ? "?" : "";
        $mode->{'zero1st'}++;
        $mode->{'even1st'}++;
        $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
        push @out, pass1 ("${indent}  ", $keyword, $mode);
        $mode->{'toeven'}--;
        $mode->{'even1st'}--;
        $mode->{'zero1st'}--;
        push @out, $encode ? ":" : "";
        push @out, $encode ? "${pt}1p()==1" : "${indent}1番目のパレットが1のとき\n";
        push @out, $encode ? "?" : "";
        $mode->{'one1st'}++;
        $mode->{'odd1st'}++;
        $mode->{'nonzero1st'}++;
        $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
        push @out, pass1 ("${indent}  ", $keyword, $mode);
        $mode->{'toeven'}--;
        $mode->{'nonzero1st'}--;
        $mode->{'odd1st'}--;
        $mode->{'one1st'}--;
      } else {
        $mode->{'zero1st'}++;
        $mode->{'even1st'}++;
        $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
        my @zero = pass1 ("${indent}  ", $keyword, $mode);
        $mode->{'toeven'}--;
        $mode->{'even1st'}--;
        $mode->{'zero1st'}--;
        $mode->{'one1st'}++;
        $mode->{'odd1st'}++;
        $mode->{'nonzero1st'}++;
        $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
        my @one = pass1 ("${indent}  ", $keyword, $mode);
        $mode->{'toeven'}--;
        $mode->{'nonzero1st'}--;
        $mode->{'odd1st'}--;
        $mode->{'one1st'}--;
        if (join ('', @zero) eq join ('', @one)) {  #0のときと1のときの手順が同じとき
          push @out, $encode ? "${pt}1p()<=1" : "${indent}1番目のパレットが1以下のとき\n";
          push @out, $encode ? "?" : "";
          push @out, @zero;
        } else {  #0のときと1のときの手順が違うとき
          push @out, $encode ? "${pt}1p()==0" : "${indent}1番目のパレットが0のとき\n";
          push @out, $encode ? "?" : "";
          push @out, @zero;
          push @out, $encode ? ":" : "";
          push @out, $encode ? "${pt}1p()==1" : "${indent}1番目のパレットが1のとき\n";
          push @out, $encode ? "?" : "";
          push @out, @one;
        }
      }
      push @out, $encode ? ":" : "";
      push @out, $encode ? "ls1(${pt}1p())==0" : "${indent}1番目のパレットが2以上の偶数のとき\n";
      push @out, $encode ? "?" : "";
      $mode->{'nonzero1st'}++;
      $mode->{'even1st'}++;
      $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
      push @out, pass1 ("${indent}  ", $keyword, $mode);
      $mode->{'toeven'}--;
      $mode->{'even1st'}--;
      $mode->{'nonzero1st'}--;
      push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが3以上の奇数のとき)\n";
      $g =~ s/[234]/1/;  #1番目だけ表示
      $mode->{'nonzero1st'}++;
      $mode->{'odd1st'}++;
      $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
      push @out, pass1 ("${indent}  ", $g, $mode);
      $mode->{'toeven'}--;
      $mode->{'odd1st'}--;
      $mode->{'nonzero1st'}--;
      push @out, $encode ? ")" : "";
      $mode->{'xword'} = $xword;
      return @out;
    }

    if ($ahead eq '') {  #今回がグラフィック

      if ($xword eq 'XHCT') {  #0でない1番目のパレットを偶数化(65536色は奇数化)したパレットのカラーが奇数のとき0でない1番目のカラーと奥のスプライト・テキストのカラーを混ぜる
        $mode->{'xword'} = '';
        if ($g =~ /(?:G|J)/) {  #65536色
          {
            push @out, $encode ? "(" : "";
            push @out, $encode ? ($dp ?
                                  "ls1(${pt}pc(tod(${pt}1p()),tod(${pt}1p())))!=0" :
                                  "ls1(${pt}pc(tod(${pt}1p())))!=0") : "${indent}1番目のパレットを奇数化したパレットのカラーが奇数のとき\n";
            push @out, $encode ? "?" : "";
            if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
              push @out, $encode ? ($dp ?
                                    "mix(${pt}pc(${pt}1p(),${pt}1p()),0)" :
                                    "mix(${pt}pc(${pt}1p()),0)") : "${indent}  1番目のカラーとカラー0を混ぜたカラー(0は黒)\n";
            } else {  #グラフィックの奥にスプライト・テキストがある
              push @out, $encode ? "mix(" : "";
              push @out, $encode ? ($dp ?
                                    "${pt}pc(${pt}1p(),${pt}1p())" :
                                    "${pt}pc(${pt}1p())") : "${indent}  1番目のカラーと\n";
              push @out, $encode ? "," : "";
              push @out, pass1 ("${indent}    ", $behind, $mode);
              push @out, $encode ? ")" : "${indent}  を混ぜたカラー(0は黒)\n";
            }
            push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットを奇数化したパレットのカラーが偶数のとき)\n";
            push @out, pass1 ("${indent}  ", $keyword, $mode);
            push @out, $encode ? ")" : "";
          }
        } elsif ($g =~ /(?:E1|F1|H|I)/) {  #グラフィック1プレーン。1番目はON、2番目と3番目と4番目はOFF
          {
            push @out, $encode ? "(" : "";
            push @out, $encode ? ($dp ?
                                  "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                                  "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
            push @out, $encode ? "?" : "";
            if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
              push @out, $encode ? ($dp ?
                                    "mix(${pt}pc(${pt}1p(),${pt}1p()),0)" :
                                    "mix(${pt}pc(${pt}1p()),0)") : "${indent}  1番目のカラーとカラー0を混ぜたカラー(0は黒)\n";
            } else {  #グラフィックの奥にスプライト・テキストがある
              push @out, $encode ? "mix(" : "";
              push @out, $encode ? ($dp ?
                                    "${pt}pc(${pt}1p(),${pt}1p())" :
                                    "${pt}pc(${pt}1p())") : "${indent}  1番目のカラーと\n";
              push @out, $encode ? "," : "";
              push @out, pass1 ("${indent}    ", $behind, $mode);
              push @out, $encode ? ")" : "${indent}  を混ぜたカラー(0は黒)\n";
            }
            push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
            push @out, pass1 ("${indent}  ", $keyword, $mode);
            push @out, $encode ? ")" : "";
          }
        } elsif ($g =~ /(?:E2|F2)/) {  #グラフィック2プレーン。2番目はON、3番目と4番目はOFF。1番目はOFFのときパレット0とみなす
          {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
            push @out, $encode ? "?" : "";
            $mode->{'nonzero1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? ($dp ?
                                    "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                                    "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}  1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
              push @out, $encode ? "?" : "";
              if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                push @out, $encode ? ($dp ?
                                      "mix(${pt}pc(${pt}1p(),${pt}1p()),0)" :
                                      "mix(${pt}pc(${pt}1p()),0)") : "${indent}    1番目のカラーとカラー0を混ぜたカラー(0は黒)\n";
              } else {  #グラフィックの奥にスプライト・テキストがある
                push @out, $encode ? "mix(" : "";
                push @out, $encode ? ($dp ?
                                      "${pt}pc(${pt}1p(),${pt}1p())" :
                                      "${pt}pc(${pt}1p())") : "${indent}    1番目のカラーと\n";
                push @out, $encode ? "," : "";
                push @out, pass1 ("${indent}      ", $behind, $mode);
                push @out, $encode ? ")" : "${indent}    を混ぜたカラー(0は黒)\n";
              }
              push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
              push @out, pass1 ("${indent}    ", $keyword, $mode);
              push @out, $encode ? ")" : "";
            }
            $mode->{'nonzero1st'}--;
            push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
            $mode->{'zero1st'}++;
            $mode->{'even1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? ($dp ?
                                    "ls1(${pt}pc(tev(${pt}2p()),tev(${pt}2p())))!=0" :
                                    "ls1(${pt}pc(tev(${pt}2p())))!=0") : "${indent}  2番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
              push @out, $encode ? "?" : "";
              if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                push @out, $encode ? ($dp ?
                                      "mix(${pt}pc(${pt}2p(),${pt}2p()),0)" :
                                      "mix(${pt}pc(${pt}2p()),0)") : "${indent}    2番目のカラーとカラー0を混ぜたカラー(0は黒)\n";
              } else {  #グラフィックの奥にスプライト・テキストがある
                push @out, $encode ? "mix(" : "";
                push @out, $encode ? ($dp ?
                                      "${pt}pc(${pt}2p(),${pt}2p())" :
                                      "${pt}pc(${pt}2p())") : "${indent}    2番目のカラーと\n";
                push @out, $encode ? "," : "";
                push @out, pass1 ("${indent}      ", $behind, $mode);
                push @out, $encode ? ")" : "${indent}    を混ぜたカラー(0は黒)\n";
              }
              push @out, $encode ? ":" : "${indent}  さもなくば(2番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
              push @out, pass1 ("${indent}    ", $keyword, $mode);
              push @out, $encode ? ")" : "";
            }
            $mode->{'even1st'}--;
            $mode->{'zero1st'}--;
            push @out, $encode ? ")" : "";
          }
        } elsif ($g =~ /(?:E3)/) {  #グラフィック3プレーン。3番目はON、4番目はOFF。1番目と2番目はOFFのときパレット0とみなす
          {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
            push @out, $encode ? "?" : "";
            $mode->{'nonzero1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? ($dp ?
                                    "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                                    "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}  1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
              push @out, $encode ? "?" : "";
              if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                push @out, $encode ? ($dp ?
                                      "mix(${pt}pc(${pt}1p(),${pt}1p()),0)" :
                                      "mix(${pt}pc(${pt}1p()),0)") : "${indent}    1番目のカラーとカラー0を混ぜたカラー(0は黒)\n";
              } else {  #グラフィックの奥にスプライト・テキストがある
                push @out, $encode ? "mix(" : "";
                push @out, $encode ? ($dp ?
                                      "${pt}pc(${pt}1p(),${pt}1p())" :
                                      "${pt}pc(${pt}1p())") : "${indent}    1番目のカラーと\n";
                push @out, $encode ? "," : "";
                push @out, pass1 ("${indent}      ", $behind, $mode);
                push @out, $encode ? ")" : "${indent}    を混ぜたカラー(0は黒)\n";
              }
              push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
              push @out, pass1 ("${indent}    ", $keyword, $mode);
              push @out, $encode ? ")" : "";
            }
            $mode->{'nonzero1st'}--;
            push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
            $mode->{'zero1st'}++;
            $mode->{'even1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? "${pt}2p()!=0" : "${indent}  2番目のパレットが0でないとき\n";
              push @out, $encode ? "?" : "";
              $mode->{'nonzero2nd'}++;
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? ($dp ?
                                      "ls1(${pt}pc(tev(${pt}2p()),tev(${pt}2p())))!=0" :
                                      "ls1(${pt}pc(tev(${pt}2p())))!=0") : "${indent}    2番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                push @out, $encode ? "?" : "";
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "mix(${pt}pc(${pt}2p(),${pt}2p()),0)" :
                                        "mix(${pt}pc(${pt}2p()),0)") : "${indent}      2番目のカラーとカラー0を混ぜたカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  push @out, $encode ? "mix(" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}2p(),${pt}2p())" :
                                        "${pt}pc(${pt}2p())") : "${indent}      2番目のカラーと\n";
                  push @out, $encode ? "," : "";
                  push @out, pass1 ("${indent}        ", $behind, $mode);
                  push @out, $encode ? ")" : "${indent}      を混ぜたカラー(0は黒)\n";
                }
                push @out, $encode ? ":" : "${indent}    さもなくば(2番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                push @out, pass1 ("${indent}      ", $keyword, $mode);
                push @out, $encode ? ")" : "";
              }
              $mode->{'nonzero2nd'}--;
              push @out, $encode ? ":" : "${indent}  さもなくば(2番目のパレットが0のとき)\n";
              $mode->{'zero2nd'}++;
              $mode->{'even2nd'}++;
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? ($dp ?
                                      "ls1(${pt}pc(tev(${pt}3p()),tev(${pt}3p())))!=0" :
                                      "ls1(${pt}pc(tev(${pt}3p())))!=0") : "${indent}    3番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                push @out, $encode ? "?" : "";
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "mix(${pt}pc(${pt}3p(),${pt}3p()),0)" :
                                        "mix(${pt}pc(${pt}3p()),0)") : "${indent}      3番目のカラーとカラー0を混ぜたカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  push @out, $encode ? "mix(" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}3p(),${pt}3p())" :
                                        "${pt}pc(${pt}3p())") : "${indent}      3番目のカラーと\n";
                  push @out, $encode ? "," : "";
                  push @out, pass1 ("${indent}        ", $behind, $mode);
                  push @out, $encode ? ")" : "${indent}      を混ぜたカラー(0は黒)\n";
                }
                push @out, $encode ? ":" : "${indent}    さもなくば(3番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                push @out, pass1 ("${indent}      ", $keyword, $mode);
                push @out, $encode ? ")" : "";
              }
              $mode->{'even2nd'}--;
              $mode->{'zero2nd'}--;
              push @out, $encode ? ")" : "";
            }
            $mode->{'even1st'}--;
            $mode->{'zero1st'}--;
            push @out, $encode ? ")" : "";
          }
        } elsif ($g =~ /(?:E4)/) {  #グラフィック4プレーン。4番目はON。1番目と2番目と3番目はOFFのときパレット0とみなす
          {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
            push @out, $encode ? "?" : "";
            $mode->{'nonzero1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? ($dp ?
                                    "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                                    "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}  1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
              push @out, $encode ? "?" : "";
              if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                push @out, $encode ? ($dp ?
                                      "mix(${pt}pc(${pt}1p(),${pt}1p()),0)" :
                                      "mix(${pt}pc(${pt}1p()),0)") : "${indent}    1番目のカラーとカラー0を混ぜたカラー(0は黒)\n";
              } else {  #グラフィックの奥にスプライト・テキストがある
                push @out, $encode ? "mix(" : "";
                push @out, $encode ? ($dp ?
                                      "${pt}pc(${pt}1p(),${pt}1p())" :
                                      "${pt}pc(${pt}1p())") : "${indent}    1番目のカラーと\n";
                push @out, $encode ? "," : "";
                push @out, pass1 ("${indent}      ", $behind, $mode);
                push @out, $encode ? ")" : "${indent}    を混ぜたカラー(0は黒)\n";
              }
              push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
              push @out, pass1 ("${indent}    ", $keyword, $mode);
              push @out, $encode ? ")" : "";
            }
            $mode->{'nonzero1st'}--;
            push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
            $mode->{'zero1st'}++;
            $mode->{'even1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? "${pt}2p()!=0" : "${indent}  2番目のパレットが0でないとき\n";
              push @out, $encode ? "?" : "";
              $mode->{'nonzero2nd'}++;
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? ($dp ?
                                      "ls1(${pt}pc(tev(${pt}2p()),tev(${pt}2p())))!=0" :
                                      "ls1(${pt}pc(tev(${pt}2p())))!=0") : "${indent}    2番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                push @out, $encode ? "?" : "";
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "mix(${pt}pc(${pt}2p(),${pt}2p()),0)" :
                                        "mix(${pt}pc(${pt}2p()),0)") : "${indent}      2番目のカラーとカラー0を混ぜたカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  push @out, $encode ? "mix(" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}2p(),${pt}2p())" :
                                        "${pt}pc(${pt}2p())") : "${indent}      2番目のカラーと\n";
                  push @out, $encode ? "," : "";
                  push @out, pass1 ("${indent}        ", $behind, $mode);
                  push @out, $encode ? ")" : "${indent}      を混ぜたカラー(0は黒)\n";
                }
                push @out, $encode ? ":" : "${indent}    さもなくば(2番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                push @out, pass1 ("${indent}      ", $keyword, $mode);
                push @out, $encode ? ")" : "";
              }
              $mode->{'nonzero2nd'}--;
              push @out, $encode ? ":" : "${indent}  さもなくば(2番目のパレットが0のとき)\n";
              $mode->{'zero2nd'}++;
              $mode->{'even2nd'}++;
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? "${pt}3p()!=0" : "${indent}    3番目のパレットが0でないとき\n";
                push @out, $encode ? "?" : "";
                $mode->{'nonzero3rd'}++;
                {
                  push @out, $encode ? "(" : "";
                  push @out, $encode ? ($dp ?
                                        "ls1(${pt}pc(tev(${pt}3p()),tev(${pt}3p())))!=0" :
                                        "ls1(${pt}pc(tev(${pt}3p())))!=0") : "${indent}      3番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                  push @out, $encode ? "?" : "";
                  if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                    push @out, $encode ? ($dp ?
                                          "mix(${pt}pc(${pt}3p(),${pt}3p()),0)" :
                                          "mix(${pt}pc(${pt}3p()),0)") : "${indent}        3番目のカラーとカラー0を混ぜたカラー(0は黒)\n";
                  } else {  #グラフィックの奥にスプライト・テキストがある
                    push @out, $encode ? "mix(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}3p(),${pt}3p())" :
                                          "${pt}pc(${pt}3p())") : "${indent}        3番目のカラーと\n";
                    push @out, $encode ? "," : "";
                    push @out, pass1 ("${indent}          ", $behind, $mode);
                    push @out, $encode ? ")" : "${indent}        を混ぜたカラー(0は黒)\n";
                  }
                  push @out, $encode ? ":" : "${indent}      さもなくば(3番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                  push @out, pass1 ("${indent}        ", $keyword, $mode);
                  push @out, $encode ? ")" : "";
                }
                $mode->{'nonzero3rd'}--;
                push @out, $encode ? ":" : "${indent}    さもなくば(3番目のパレットが0のとき)\n";
                $mode->{'zero3rd'}++;
                $mode->{'even3rd'}++;
                {
                  push @out, $encode ? "(" : "";
                  push @out, $encode ? ($dp ?
                                        "ls1(${pt}pc(tev(${pt}4p()),tev(${pt}4p())))!=0" :
                                        "ls1(${pt}pc(tev(${pt}4p())))!=0") : "${indent}      4番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                  push @out, $encode ? "?" : "";
                  if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                    push @out, $encode ? ($dp ?
                                          "mix(${pt}pc(${pt}4p(),${pt}4p()),0)" :
                                          "mix(${pt}pc(${pt}4p()),0)") : "${indent}        4番目のカラーとカラー0を混ぜたカラー(0は黒)\n";
                  } else {  #グラフィックの奥にスプライト・テキストがある
                    push @out, $encode ? "mix(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}4p(),${pt}4p())" :
                                          "${pt}pc(${pt}4p())") : "${indent}        4番目のカラーと\n";
                    push @out, $encode ? "," : "";
                    push @out, pass1 ("${indent}          ", $behind, $mode);
                    push @out, $encode ? ")" : "${indent}        を混ぜたカラー(0は黒)\n";
                  }
                  push @out, $encode ? ":" : "${indent}      さもなくば(4番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                  push @out, pass1 ("${indent}        ", $keyword, $mode);
                  push @out, $encode ? ")" : "";
                }
                $mode->{'even3rd'}--;
                $mode->{'zero3rd'}--;
                push @out, $encode ? ")" : "";
              }
              $mode->{'even2nd'}--;
              $mode->{'zero2nd'}--;
              push @out, $encode ? ")" : "";
            }
            $mode->{'even1st'}--;
            $mode->{'zero1st'}--;
            push @out, $encode ? ")" : "";
          }
        } else {
          die $keyword;
        }
        $mode->{'xword'} = $xword;
        return @out;
      }

      if ($xword eq 'XHCG') {  #0でない1番目のパレットを偶数化したパレットのカラーが奇数のときそれと2番目のパレットを奇数化したパレットのカラーを混ぜる
        $mode->{'xword'} = '';
        if ($g =~ /(?:E1|F1|G|H|I|J)/) {  #グラフィック1プレーン。1番目はON、2番目と3番目と4番目はOFF
          {
            push @out, $encode ? "(" : "";
            push @out, $encode ? ($dp ?
                                  "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                                  "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? ($dp ?
                                  "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                  "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q())))") : "${indent}  1番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラー(0は黒)\n";
            push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? "ls1(${pt}1p())!=0" : "${indent}  1番目のパレットが奇数のとき\n";
              push @out, $encode ? "?" : "";
              $mode->{'odd1st'}++;
              $mode->{'nonzero1st'}++;
              if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                push @out, $encode ? ($dp ?
                                      "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                      "${pt}pc(tod(${pt}2q()))") : "${indent}    2番目(ONとみなす)のパレットを奇数化したパレットのカラー(0は黒)\n";
              } else {  #グラフィックの奥にスプライト・テキストがある
                {
                  push @out, $encode ? "(" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))!=0" :
                                        "${pt}pc(tod(${pt}2q()))!=0") : "${indent}    2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0でないとき\n";
                  push @out, $encode ? "?" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                        "${pt}pc(tod(${pt}2q()))") : "${indent}      2番目(ONとみなす)のパレットを奇数化したパレットのカラー\n";
                  push @out, $encode ? ":" : "${indent}    さもなくば(2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0のとき)\n";
                  push @out, pass1 ("${indent}      ", $behind, $mode);
                  push @out, $encode ? ")" : "";
                }
              }
              $mode->{'nonzero1st'}--;
              $mode->{'odd1st'}--;
              push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットが偶数のとき)\n";
              $mode->{'even1st'}++;
              if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                push @out, $encode ? ($dp ?
                                      "${pt}pc(${pt}1p(),${pt}1p())" :
                                      "${pt}pc(${pt}1p())") : "${indent}    1番目のカラー(0は黒)\n";
              } else {  #グラフィックの奥にスプライト・テキストがある
                {
                  push @out, $encode ? "(" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}1p(),${pt}1p())!=0" :
                                        "${pt}pc(${pt}1p())!=0") : "${indent}    1番目のカラーが0でないとき\n";
                  push @out, $encode ? "?" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}1p(),${pt}1p())" :
                                        "${pt}pc(${pt}1p())") : "${indent}      1番目のカラー\n";
                  push @out, $encode ? ":" : "${indent}    さもなくば(1番目のカラーが0のとき)\n";
                  push @out, pass1 ("${indent}      ", $behind, $mode);
                  push @out, $encode ? ")" : "";
                }
              }
              $mode->{'even1st'}--;
              push @out, $encode ? ")" : "";
            }
            push @out, $encode ? ")" : "";
          }
        } elsif ($g =~ /(?:E2|F2)/) {  #グラフィック2プレーン。2番目はON、3番目と4番目はOFF。1番目はOFFのときパレット0とみなす
          {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
            push @out, $encode ? "?" : "";
            $mode->{'nonzero1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? ($dp ?
                                    "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                                    "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}  1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
              push @out, $encode ? "?" : "";
              push @out, $encode ? ($dp ?
                                    "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                    "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q())))") : "${indent}    1番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラー(0は黒)\n";
              push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? "ls1(${pt}1p())!=0" : "${indent}    1番目のパレットが奇数のとき\n";
                push @out, $encode ? "?" : "";
                $mode->{'odd1st'}++;
                $mode->{'nonzero1st'}++;
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                        "${pt}pc(tod(${pt}2q()))") : "${indent}      2番目(ONとみなす)のパレットを奇数化したパレットのカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))!=0" :
                                          "${pt}pc(tod(${pt}2q()))!=0") : "${indent}      2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                          "${pt}pc(tod(${pt}2q()))") : "${indent}        2番目(ONとみなす)のパレットを奇数化したパレットのカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                $mode->{'nonzero1st'}--;
                $mode->{'odd1st'}--;
                push @out, $encode ? ":" : "${indent}    さもなくば(1番目のパレットが偶数のとき)\n";
                $mode->{'even1st'}++;
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}1p(),${pt}1p())" :
                                        "${pt}pc(${pt}1p())") : "${indent}      1番目のカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}1p(),${pt}1p())!=0" :
                                          "${pt}pc(${pt}1p())!=0") : "${indent}      1番目のカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}1p(),${pt}1p())" :
                                          "${pt}pc(${pt}1p())") : "${indent}        1番目のカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(1番目のカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                $mode->{'even1st'}--;
                push @out, $encode ? ")" : "";
              }
              push @out, $encode ? ")" : "";
            }
            $mode->{'nonzero1st'}--;
            push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
            $mode->{'zero1st'}++;
            $mode->{'even1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? ($dp ?
                                    "ls1(${pt}pc(tev(${pt}2p()),tev(${pt}2p())))!=0" :
                                    "ls1(${pt}pc(tev(${pt}2p())))!=0") : "${indent}  2番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
              push @out, $encode ? "?" : "";
              push @out, $encode ? ($dp ?
                                    "mix(${pt}pc(tev(${pt}2p()),tev(${pt}2p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                    "mix(${pt}pc(tev(${pt}2p())),${pt}pc(tod(${pt}2q())))") : "${indent}    2番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラー(0は黒)\n";
              push @out, $encode ? ":" : "${indent}  さもなくば(2番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
              if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                push @out, $encode ? ($dp ?
                                      "${pt}pc(${pt}2p(),${pt}2p())" :
                                      "${pt}pc(${pt}2p())") : "${indent}    2番目のカラー(0は黒)\n";
              } else {  #グラフィックの奥にスプライト・テキストがある
                {
                  push @out, $encode ? "(" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}2p(),${pt}2p())!=0" :
                                        "${pt}pc(${pt}2p())!=0") : "${indent}    2番目のカラーが0でないとき\n";
                  push @out, $encode ? "?" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}2p(),${pt}2p())" :
                                        "${pt}pc(${pt}2p())") : "${indent}      2番目のカラー\n";
                  push @out, $encode ? ":" : "${indent}    さもなくば(2番目のカラーが0のとき)\n";
                  push @out, pass1 ("${indent}      ", $behind, $mode);
                  push @out, $encode ? ")" : "";
                }
              }
              push @out, $encode ? ")" : "";
            }
            $mode->{'even1st'}--;
            $mode->{'zero1st'}--;
            push @out, $encode ? ")" : "";
          }
        } elsif ($g =~ /(?:E3)/) {  #グラフィック3プレーン。3番目はON、4番目はOFF。1番目と2番目はOFFのときパレット0とみなす
          {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
            push @out, $encode ? "?" : "";
            $mode->{'nonzero1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? ($dp ?
                                    "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                                    "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}  1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
              push @out, $encode ? "?" : "";
              push @out, $encode ? ($dp ?
                                    "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                    "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q())))") : "${indent}    1番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラー(0は黒)\n";
              push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? "ls1(${pt}1p())!=0" : "${indent}    1番目のパレットが奇数のとき\n";
                push @out, $encode ? "?" : "";
                $mode->{'odd1st'}++;
                $mode->{'nonzero1st'}++;
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                        "${pt}pc(tod(${pt}2q()))") : "${indent}      2番目(ONとみなす)のパレットを奇数化したパレットのカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))!=0" :
                                          "${pt}pc(tod(${pt}2q()))!=0") : "${indent}      2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                          "${pt}pc(tod(${pt}2q()))") : "${indent}        2番目(ONとみなす)のパレットを奇数化したパレットのカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                $mode->{'nonzero1st'}--;
                $mode->{'odd1st'}--;
                push @out, $encode ? ":" : "${indent}    さもなくば(1番目のパレットが偶数のとき)\n";
                $mode->{'even1st'}++;
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}1p(),${pt}1p())" :
                                        "${pt}pc(${pt}1p())") : "${indent}      1番目のカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}1p(),${pt}1p())!=0" :
                                          "${pt}pc(${pt}1p())!=0") : "${indent}      1番目のカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}1p(),${pt}1p())" :
                                          "${pt}pc(${pt}1p())") : "${indent}        1番目のカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(1番目のカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                $mode->{'even1st'}--;
                push @out, $encode ? ")" : "";
              }
              push @out, $encode ? ")" : "";
            }
            $mode->{'nonzero1st'}--;
            push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
            $mode->{'zero1st'}++;
            $mode->{'even1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? "${pt}2p()!=0" : "${indent}  2番目のパレットが0でないとき\n";
              push @out, $encode ? "?" : "";
              $mode->{'nonzero2nd'}++;
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? ($dp ?
                                      "ls1(${pt}pc(tev(${pt}2p()),tev(${pt}2p())))!=0" :
                                      "ls1(${pt}pc(tev(${pt}2p())))!=0") : "${indent}    2番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                push @out, $encode ? "?" : "";
                push @out, $encode ? ($dp ?
                                      "mix(${pt}pc(tev(${pt}2p()),tev(${pt}2p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                      "mix(${pt}pc(tev(${pt}2p())),${pt}pc(tod(${pt}2q())))") : "${indent}      2番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラー(0は黒)\n";
                push @out, $encode ? ":" : "${indent}    さもなくば(2番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}2p(),${pt}2p())" :
                                        "${pt}pc(${pt}2p())") : "${indent}      2番目のカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}2p(),${pt}2p())!=0" :
                                          "${pt}pc(${pt}2p())!=0") : "${indent}      2番目のカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}2p(),${pt}2p())" :
                                          "${pt}pc(${pt}2p())") : "${indent}        2番目のカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(2番目のカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                push @out, $encode ? ")" : "";
              }
              $mode->{'nonzero2nd'}--;
              push @out, $encode ? ":" : "${indent}  さもなくば(2番目のパレットが0のとき)\n";
              $mode->{'zero2nd'}++;
              $mode->{'even2nd'}++;
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? ($dp ?
                                      "ls1(${pt}pc(tev(${pt}3p()),tev(${pt}3p())))!=0" :
                                      "ls1(${pt}pc(tev(${pt}3p())))!=0") : "${indent}    3番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                push @out, $encode ? "?" : "";
                push @out, $encode ? ($dp ?
                                      "mix(${pt}pc(tev(${pt}3p()),tev(${pt}3p())),${pt}pc(1,1))" :
                                      "mix(${pt}pc(tev(${pt}3p())),${pt}pc(1))") : "${indent}      3番目のパレットを偶数化したパレットのカラーとパレット1のカラーを混ぜたカラー(0は黒)\n";
                push @out, $encode ? ":" : "${indent}    さもなくば(3番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                {
                  push @out, $encode ? "(" : "";
                  push @out, $encode ? "ls1(${pt}3p())!=0" : "${indent}      3番目のパレットが奇数のとき\n";
                  push @out, $encode ? "?" : "";
                  $mode->{'odd3rd'}++;
                  $mode->{'nonzero3rd'}++;
                  if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(1,1)" :
                                          "${pt}pc(1)") : "${indent}        パレット1のカラー(0は黒)\n";
                  } else {  #グラフィックの奥にスプライト・テキストがある
                    {
                      push @out, $encode ? "(" : "";
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(1,1)!=0" :
                                            "${pt}pc(1)!=0") : "${indent}        パレット1のカラーが0でないとき\n";
                      push @out, $encode ? "?" : "";
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(1,1)" :
                                            "${pt}pc(1)") : "${indent}          パレット1のカラー\n";
                      push @out, $encode ? ":" : "${indent}        さもなくば(パレット1のカラーが0のとき)\n";
                      push @out, pass1 ("${indent}          ", $behind, $mode);
                      push @out, $encode ? ")" : "";
                    }
                  }
                  $mode->{'nonzero3rd'}--;
                  $mode->{'odd3rd'}--;
                  push @out, $encode ? ":" : "${indent}      さもなくば(3番目のパレットが偶数のとき)\n";
                  $mode->{'even3rd'}++;
                  if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}3p(),${pt}3p())" :
                                          "${pt}pc(${pt}3p())") : "${indent}        3番目のカラー(0は黒)\n";
                  } else {  #グラフィックの奥にスプライト・テキストがある
                    {
                      push @out, $encode ? "(" : "";
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(${pt}3p(),${pt}3p())!=0" :
                                            "${pt}pc(${pt}3p())!=0") : "${indent}        3番目のカラーが0でないとき\n";
                      push @out, $encode ? "?" : "";
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(${pt}3p(),${pt}3p())" :
                                            "${pt}pc(${pt}3p())") : "${indent}          3番目のカラー\n";
                      push @out, $encode ? ":" : "${indent}        さもなくば(3番目のカラーが0のとき)\n";
                      push @out, pass1 ("${indent}          ", $behind, $mode);
                      push @out, $encode ? ")" : "";
                    }
                  }
                  $mode->{'even3rd'}--;
                  push @out, $encode ? ")" : "";
                }
                push @out, $encode ? ")" : "";
              }
              $mode->{'even2nd'}--;
              $mode->{'zero2nd'}--;
              push @out, $encode ? ")" : "";
            }
            $mode->{'even1st'}--;
            $mode->{'zero1st'}--;
            push @out, $encode ? ")" : "";
          }
        } elsif ($g =~ /(?:E4)/) {  #グラフィック4プレーン。4番目はON。1番目と2番目と3番目はOFFのときパレット0とみなす
          {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
            push @out, $encode ? "?" : "";
            $mode->{'nonzero1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? ($dp ?
                                    "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                                    "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}  1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
              push @out, $encode ? "?" : "";
              push @out, $encode ? ($dp ?
                                    "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                    "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q())))") : "${indent}    1番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラー(0は黒)\n";
              push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? "ls1(${pt}1p())!=0" : "${indent}    1番目のパレットが奇数のとき\n";
                push @out, $encode ? "?" : "";
                $mode->{'odd1st'}++;
                $mode->{'nonzero1st'}++;
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                        "${pt}pc(tod(${pt}2q()))") : "${indent}      2番目(ONとみなす)のパレットを奇数化したパレットのカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))!=0" :
                                          "${pt}pc(tod(${pt}2q()))!=0") : "${indent}      2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                          "${pt}pc(tod(${pt}2q()))") : "${indent}        2番目(ONとみなす)のパレットを奇数化したパレットのカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                $mode->{'nonzero1st'}--;
                $mode->{'odd1st'}--;
                push @out, $encode ? ":" : "${indent}    さもなくば(1番目のパレットが偶数のとき)\n";
                $mode->{'even1st'}++;
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}1p(),${pt}1p())" :
                                        "${pt}pc(${pt}1p())") : "${indent}      1番目のカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}1p(),${pt}1p())!=0" :
                                          "${pt}pc(${pt}1p())!=0") : "${indent}      1番目のカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}1p(),${pt}1p())" :
                                          "${pt}pc(${pt}1p())") : "${indent}        1番目のカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(1番目のカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                $mode->{'even1st'}--;
                push @out, $encode ? ")" : "";
              }
              push @out, $encode ? ")" : "";
            }
            $mode->{'nonzero1st'}--;
            push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
            $mode->{'zero1st'}++;
            $mode->{'even1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? "${pt}2p()!=0" : "${indent}  2番目のパレットが0でないとき\n";
              push @out, $encode ? "?" : "";
              $mode->{'nonzero2nd'}++;
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? ($dp ?
                                      "ls1(${pt}pc(tev(${pt}2p()),tev(${pt}2p())))!=0" :
                                      "ls1(${pt}pc(tev(${pt}2p())))!=0") : "${indent}    2番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                push @out, $encode ? "?" : "";
                push @out, $encode ? ($dp ?
                                      "mix(${pt}pc(tev(${pt}2p()),tev(${pt}2p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                      "mix(${pt}pc(tev(${pt}2p())),${pt}pc(tod(${pt}2q())))") : "${indent}      2番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラー(0は黒)\n";
                push @out, $encode ? ":" : "${indent}    さもなくば(2番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}2p(),${pt}2p())" :
                                        "${pt}pc(${pt}2p())") : "${indent}      2番目のカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}2p(),${pt}2p())!=0" :
                                          "${pt}pc(${pt}2p())!=0") : "${indent}      2番目のカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}2p(),${pt}2p())" :
                                          "${pt}pc(${pt}2p())") : "${indent}        2番目のカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(2番目のカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                push @out, $encode ? ")" : "";
              }
              $mode->{'nonzero2nd'}--;
              push @out, $encode ? ":" : "${indent}  さもなくば(2番目のパレットが0のとき)\n";
              $mode->{'zero2nd'}++;
              $mode->{'even2nd'}++;
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? "${pt}3p()!=0" : "${indent}    3番目のパレットが0でないとき\n";
                push @out, $encode ? "?" : "";
                $mode->{'nonzero3rd'}++;
                {
                  push @out, $encode ? "(" : "";
                  push @out, $encode ? ($dp ?
                                        "ls1(${pt}pc(tev(${pt}3p()),tev(${pt}3p())))!=0" :
                                        "ls1(${pt}pc(tev(${pt}3p())))!=0") : "${indent}      3番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                  push @out, $encode ? "?" : "";
                  push @out, $encode ? ($dp ?
                                        "mix(${pt}pc(tev(${pt}3p()),tev(${pt}3p())),${pt}pc(1,1))" :
                                        "mix(${pt}pc(tev(${pt}3p())),${pt}pc(1))") : "${indent}        3番目のパレットを偶数化したパレットのカラーとパレット1のカラーを混ぜたカラー(0は黒)\n";
                  push @out, $encode ? ":" : "${indent}      さもなくば(3番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? "ls1(${pt}3p())!=0" : "${indent}        3番目のパレットが奇数のとき\n";
                    push @out, $encode ? "?" : "";
                    $mode->{'odd3rd'}++;
                    $mode->{'nonzero3rd'}++;
                    if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(1,1)" :
                                            "${pt}pc(1)") : "${indent}          パレット1のカラー(0は黒)\n";
                    } else {  #グラフィックの奥にスプライト・テキストがある
                      {
                        push @out, $encode ? "(" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(1,1)!=0" :
                                              "${pt}pc(1)!=0") : "${indent}          パレット1のカラーが0でないとき\n";
                        push @out, $encode ? "?" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(1,1)" :
                                              "${pt}pc(1)") : "${indent}            パレット1のカラー\n";
                        push @out, $encode ? ":" : "${indent}          さもなくば(パレット1のカラーが0のとき)\n";
                        push @out, pass1 ("${indent}            ", $behind, $mode);
                        push @out, $encode ? ")" : "";
                      }
                    }
                    $mode->{'nonzero3rd'}--;
                    $mode->{'odd3rd'}--;
                    push @out, $encode ? ":" : "${indent}        さもなくば(3番目のパレットが偶数のとき)\n";
                    $mode->{'even3rd'}++;
                    if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(${pt}3p(),${pt}3p())" :
                                            "${pt}pc(${pt}3p())") : "${indent}          3番目のカラー(0は黒)\n";
                    } else {  #グラフィックの奥にスプライト・テキストがある
                      {
                        push @out, $encode ? "(" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(${pt}3p(),${pt}3p())!=0" :
                                              "${pt}pc(${pt}3p())!=0") : "${indent}          3番目のカラーが0でないとき\n";
                        push @out, $encode ? "?" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(${pt}3p(),${pt}3p())" :
                                              "${pt}pc(${pt}3p())") : "${indent}            3番目のカラー\n";
                        push @out, $encode ? ":" : "${indent}          さもなくば(3番目のカラーが0のとき)\n";
                        push @out, pass1 ("${indent}            ", $behind, $mode);
                        push @out, $encode ? ")" : "";
                      }
                    }
                    $mode->{'even3rd'}--;
                    push @out, $encode ? ")" : "";
                  }
                  push @out, $encode ? ")" : "";
                }
                $mode->{'nonzero3rd'}--;
                push @out, $encode ? ":" : "${indent}    さもなくば(3番目のパレットが0のとき)\n";
                $mode->{'zero3rd'}++;
                $mode->{'even3rd'}++;
                {
                  push @out, $encode ? "(" : "";
                  push @out, $encode ? ($dp ?
                                        "ls1(${pt}pc(tev(${pt}4p()),tev(${pt}4p())))!=0" :
                                        "ls1(${pt}pc(tev(${pt}4p())))!=0") : "${indent}      4番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                  push @out, $encode ? "?" : "";
                  push @out, $encode ? ($dp ?
                                        "mix(${pt}pc(tev(${pt}4p()),tev(${pt}4p())),${pt}pc(1,1))" :
                                        "mix(${pt}pc(tev(${pt}4p())),${pt}pc(1))") : "${indent}        4番目のパレットを偶数化したパレットのカラーとパレット1のカラーを混ぜたカラー(0は黒)\n";
                  push @out, $encode ? ":" : "${indent}      さもなくば(4番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? "ls1(${pt}4p())!=0" : "${indent}        4番目のパレットが奇数のとき\n";
                    push @out, $encode ? "?" : "";
                    $mode->{'odd4th'}++;
                    $mode->{'nonzero4th'}++;
                    if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(1,1)" :
                                            "${pt}pc(1)") : "${indent}          パレット1のカラー(0は黒)\n";
                    } else {  #グラフィックの奥にスプライト・テキストがある
                      {
                        push @out, $encode ? "(" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(1,1)!=0" :
                                              "${pt}pc(1)!=0") : "${indent}          パレット1のカラーが0でないとき\n";
                        push @out, $encode ? "?" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(1,1)" :
                                              "${pt}pc(1)") : "${indent}            パレット1のカラー\n";
                        push @out, $encode ? ":" : "${indent}          さもなくば(パレット1のカラーが0のとき)\n";
                        push @out, pass1 ("${indent}            ", $behind, $mode);
                        push @out, $encode ? ")" : "";
                      }
                    }
                    $mode->{'nonzero4th'}--;
                    $mode->{'odd4th'}--;
                    push @out, $encode ? ":" : "${indent}        さもなくば(4番目のパレットが偶数のとき)\n";
                    $mode->{'even4th'}++;
                    if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(${pt}4p(),${pt}4p())" :
                                            "${pt}pc(${pt}4p())") : "${indent}          4番目のカラー(0は黒)\n";
                    } else {  #グラフィックの奥にスプライト・テキストがある
                      {
                        push @out, $encode ? "(" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(${pt}4p(),${pt}4p())!=0" :
                                              "${pt}pc(${pt}4p())!=0") : "${indent}          4番目のカラーが0でないとき\n";
                        push @out, $encode ? "?" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(${pt}4p(),${pt}4p())" :
                                              "${pt}pc(${pt}4p())") : "${indent}            4番目のカラー\n";
                        push @out, $encode ? ":" : "${indent}          さもなくば(4番目のカラーが0のとき)\n";
                        push @out, pass1 ("${indent}            ", $behind, $mode);
                        push @out, $encode ? ")" : "";
                      }
                    }
                    $mode->{'even4th'}--;
                    push @out, $encode ? ")" : "";
                  }
                  push @out, $encode ? ")" : "";
                }
                $mode->{'even3rd'}--;
                $mode->{'zero3rd'}--;
                push @out, $encode ? ")" : "";
              }
              $mode->{'even2nd'}--;
              $mode->{'zero2nd'}--;
              push @out, $encode ? ")" : "";
            }
            $mode->{'even1st'}--;
            $mode->{'zero1st'}--;
            push @out, $encode ? ")" : "";
          }
        } else {
          die $keyword;
        }
        $mode->{'xword'} = $xword;
        return @out;
      }

      if ($xword eq 'XHCGT') {  #0でない1番目のパレットを偶数化したパレットのカラーが奇数のときそれと2番目のパレットを奇数化したパレットのカラーを混ぜてさらに奥のスプライト・テキストのカラーを混ぜる
        $mode->{'xword'} = '';
        if ($g =~ /(?:E1|F1|G|H|I|J)/) {  #グラフィック1プレーン。1番目はON、2番目と3番目と4番目はOFF
          {
            push @out, $encode ? "(" : "";
            push @out, $encode ? ($dp ?
                                  "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                                  "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
            push @out, $encode ? "?" : "";
            if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
              push @out, $encode ? ($dp ?
                                    "mix(mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q()))),0)" :
                                    "mix(mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q()))),0)") : "${indent}  1番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラーにさらにカラー0を混ぜたカラー(0は黒)\n";
            } else {  #グラフィックの奥にスプライト・テキストがある
              push @out, $encode ? "mix(" : "";
              push @out, $encode ? ($dp ?
                                    "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                    "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q())))") : "${indent}  1番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラーにさらに\n";
              push @out, $encode ? "," : "";
              push @out, pass1 ("${indent}    ", $behind, $mode);
              push @out, $encode ? ")" : "${indent}  を混ぜたカラー(0は黒)\n";
            }
            push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? "ls1(${pt}1p())!=0" : "${indent}  1番目のパレットが奇数のとき\n";
              push @out, $encode ? "?" : "";
              $mode->{'odd1st'}++;
              $mode->{'nonzero1st'}++;
              if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                push @out, $encode ? ($dp ?
                                      "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                      "${pt}pc(tod(${pt}2q()))") : "${indent}    2番目(ONとみなす)のパレットを奇数化したパレットのカラー(0は黒)\n";
              } else {  #グラフィックの奥にスプライト・テキストがある
                {
                  push @out, $encode ? "(" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))!=0" :
                                        "${pt}pc(tod(${pt}2q()))!=0") : "${indent}    2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0でないとき\n";
                  push @out, $encode ? "?" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                        "${pt}pc(tod(${pt}2q()))") : "${indent}      2番目(ONとみなす)のパレットを奇数化したパレットのカラー\n";
                  push @out, $encode ? ":" : "${indent}    さもなくば(2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0のとき)\n";
                  push @out, pass1 ("${indent}      ", $behind, $mode);
                  push @out, $encode ? ")" : "";
                }
              }
              $mode->{'nonzero1st'}--;
              $mode->{'odd1st'}--;
              push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットが偶数のとき)\n";
              $mode->{'even1st'}++;
              if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                push @out, $encode ? ($dp ?
                                      "${pt}pc(${pt}1p(),${pt}1p())" :
                                      "${pt}pc(${pt}1p())") : "${indent}    1番目のカラー(0は黒)\n";
              } else {  #グラフィックの奥にスプライト・テキストがある
                {
                  push @out, $encode ? "(" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}1p(),${pt}1p())!=0" :
                                        "${pt}pc(${pt}1p())!=0") : "${indent}    1番目のカラーが0でないとき\n";
                  push @out, $encode ? "?" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}1p(),${pt}1p())" :
                                        "${pt}pc(${pt}1p())") : "${indent}      1番目のカラー\n";
                  push @out, $encode ? ":" : "${indent}    さもなくば(1番目のカラーが0のとき)\n";
                  push @out, pass1 ("${indent}      ", $behind, $mode);
                  push @out, $encode ? ")" : "";
                }
              }
              $mode->{'even1st'}--;
              push @out, $encode ? ")" : "";
            }
            push @out, $encode ? ")" : "";
          }
        } elsif ($g =~ /(?:E2|F2)/) {  #グラフィック2プレーン。2番目はON、3番目と4番目はOFF。1番目はOFFのときパレット0とみなす
          {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
            push @out, $encode ? "?" : "";
            $mode->{'nonzero1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? ($dp ?
                                    "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                                    "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}  1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
              push @out, $encode ? "?" : "";
              if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                push @out, $encode ? ($dp ?
                                      "mix(mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q()))),0)" :
                                      "mix(mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q()))),0)") : "${indent}    1番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラーにさらにカラー0を混ぜたカラー(0は黒)\n";
              } else {  #グラフィックの奥にスプライト・テキストがある
                push @out, $encode ? "mix(" : "";
                push @out, $encode ? ($dp ?
                                      "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                      "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q())))") : "${indent}    1番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラーにさらに\n";
                push @out, $encode ? "," : "";
                push @out, pass1 ("${indent}      ", $behind, $mode);
                push @out, $encode ? ")" : "${indent}    を混ぜたカラー(0は黒)\n";
              }
              push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? "ls1(${pt}1p())!=0" : "${indent}    1番目のパレットが奇数のとき\n";
                push @out, $encode ? "?" : "";
                $mode->{'odd1st'}++;
                $mode->{'nonzero1st'}++;
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                        "${pt}pc(tod(${pt}2q()))") : "${indent}      2番目(ONとみなす)のパレットを奇数化したパレットのカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))!=0" :
                                          "${pt}pc(tod(${pt}2q()))!=0") : "${indent}      2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                          "${pt}pc(tod(${pt}2q()))") : "${indent}        2番目(ONとみなす)のパレットを奇数化したパレットのカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                $mode->{'nonzero1st'}--;
                $mode->{'odd1st'}--;
                push @out, $encode ? ":" : "${indent}    さもなくば(1番目のパレットが偶数のとき)\n";
                $mode->{'even1st'}++;
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}1p(),${pt}1p())" :
                                        "${pt}pc(${pt}1p())") : "${indent}      1番目のカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}1p(),${pt}1p())!=0" :
                                          "${pt}pc(${pt}1p())!=0") : "${indent}      1番目のカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}1p(),${pt}1p())" :
                                          "${pt}pc(${pt}1p())") : "${indent}        1番目のカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(1番目のカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                $mode->{'even1st'}--;
                push @out, $encode ? ")" : "";
              }
              push @out, $encode ? ")" : "";
            }
            $mode->{'nonzero1st'}--;
            push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
            $mode->{'zero1st'}++;
            $mode->{'even1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? ($dp ?
                                    "ls1(${pt}pc(tev(${pt}2p()),tev(${pt}2p())))!=0" :
                                    "ls1(${pt}pc(tev(${pt}2p())))!=0") : "${indent}  2番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
              push @out, $encode ? "?" : "";
              if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                push @out, $encode ? ($dp ?
                                      "mix(mix(${pt}pc(tev(${pt}2p()),tev(${pt}2p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q()))),0)" :
                                      "mix(mix(${pt}pc(tev(${pt}2p())),${pt}pc(tod(${pt}2q()))),0)") : "${indent}    2番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラーにさらにカラー0を混ぜたカラー(0は黒)\n";
              } else {  #グラフィックの奥にスプライト・テキストがある
                push @out, $encode ? "mix(" : "";
                push @out, $encode ? ($dp ?
                                      "mix(${pt}pc(tev(${pt}2p()),tev(${pt}2p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                      "mix(${pt}pc(tev(${pt}2p())),${pt}pc(tod(${pt}2q())))") : "${indent}    2番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラーにさらに\n";
                push @out, $encode ? "," : "";
                push @out, pass1 ("${indent}      ", $behind, $mode);
                push @out, $encode ? ")" : "${indent}    を混ぜたカラー(0は黒)\n";
              }
              push @out, $encode ? ":" : "${indent}  さもなくば(2番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
              if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                push @out, $encode ? ($dp ?
                                      "${pt}pc(${pt}2p(),${pt}2p())" :
                                      "${pt}pc(${pt}2p())") : "${indent}    2番目のカラー(0は黒)\n";
              } else {  #グラフィックの奥にスプライト・テキストがある
                {
                  push @out, $encode ? "(" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}2p(),${pt}2p())!=0" :
                                        "${pt}pc(${pt}2p())!=0") : "${indent}    2番目のカラーが0でないとき\n";
                  push @out, $encode ? "?" : "";
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}2p(),${pt}2p())" :
                                        "${pt}pc(${pt}2p())") : "${indent}      2番目のカラー\n";
                  push @out, $encode ? ":" : "${indent}    さもなくば(2番目のカラーが0のとき)\n";
                  push @out, pass1 ("${indent}      ", $behind, $mode);
                  push @out, $encode ? ")" : "";
                }
              }
              push @out, $encode ? ")" : "";
            }
            $mode->{'even1st'}--;
            $mode->{'zero1st'}--;
            push @out, $encode ? ")" : "";
          }
        } elsif ($g =~ /(?:E3)/) {  #グラフィック3プレーン。3番目はON、4番目はOFF。1番目と2番目はOFFのときパレット0とみなす
          {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
            push @out, $encode ? "?" : "";
            $mode->{'nonzero1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? ($dp ?
                                    "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                                    "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}  1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
              push @out, $encode ? "?" : "";
              if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                push @out, $encode ? ($dp ?
                                      "mix(mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q()))),0)" :
                                      "mix(mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q()))),0)") : "${indent}    1番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラーにさらにカラー0を混ぜたカラー(0は黒)\n";
              } else {  #グラフィックの奥にスプライト・テキストがある
                push @out, $encode ? "mix(" : "";
                push @out, $encode ? ($dp ?
                                      "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                      "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q())))") : "${indent}    1番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラーにさらに\n";
                push @out, $encode ? "," : "";
                push @out, pass1 ("${indent}      ", $behind, $mode);
                push @out, $encode ? ")" : "${indent}    を混ぜたカラー(0は黒)\n";
              }
              push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? "ls1(${pt}1p())!=0" : "${indent}    1番目のパレットが奇数のとき\n";
                push @out, $encode ? "?" : "";
                $mode->{'odd1st'}++;
                $mode->{'nonzero1st'}++;
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                        "${pt}pc(tod(${pt}2q()))") : "${indent}      2番目(ONとみなす)のパレットを奇数化したパレットのカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))!=0" :
                                          "${pt}pc(tod(${pt}2q()))!=0") : "${indent}      2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                          "${pt}pc(tod(${pt}2q()))") : "${indent}        2番目(ONとみなす)のパレットを奇数化したパレットのカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                $mode->{'nonzero1st'}--;
                $mode->{'odd1st'}--;
                push @out, $encode ? ":" : "${indent}    さもなくば(1番目のパレットが偶数のとき)\n";
                $mode->{'even1st'}++;
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}1p(),${pt}1p())" :
                                        "${pt}pc(${pt}1p())") : "${indent}      1番目のカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}1p(),${pt}1p())!=0" :
                                          "${pt}pc(${pt}1p())!=0") : "${indent}      1番目のカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}1p(),${pt}1p())" :
                                          "${pt}pc(${pt}1p())") : "${indent}        1番目のカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(1番目のカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                $mode->{'even1st'}--;
                push @out, $encode ? ")" : "";
              }
              push @out, $encode ? ")" : "";
            }
            $mode->{'nonzero1st'}--;
            push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
            $mode->{'zero1st'}++;
            $mode->{'even1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? "${pt}2p()!=0" : "${indent}  2番目のパレットが0でないとき\n";
              push @out, $encode ? "?" : "";
              $mode->{'nonzero2nd'}++;
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? ($dp ?
                                      "ls1(${pt}pc(tev(${pt}2p()),tev(${pt}2p())))!=0" :
                                      "ls1(${pt}pc(tev(${pt}2p())))!=0") : "${indent}    2番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                push @out, $encode ? "?" : "";
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "mix(mix(${pt}pc(tev(${pt}2p()),tev(${pt}2p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q()))),0)" :
                                        "mix(mix(${pt}pc(tev(${pt}2p())),${pt}pc(tod(${pt}2q()))),0)") : "${indent}      2番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラーにさらにカラー0を混ぜたカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  push @out, $encode ? "mix(" : "";
                  push @out, $encode ? ($dp ?
                                        "mix(${pt}pc(tev(${pt}2p()),tev(${pt}2p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                        "mix(${pt}pc(tev(${pt}2p())),${pt}pc(tod(${pt}2q())))") : "${indent}      2番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラーにさらに\n";
                  push @out, $encode ? "," : "";
                  push @out, pass1 ("${indent}        ", $behind, $mode);
                  push @out, $encode ? ")" : "${indent}      を混ぜたカラー(0は黒)\n";
                }
                push @out, $encode ? ":" : "${indent}    さもなくば(2番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}2p(),${pt}2p())" :
                                        "${pt}pc(${pt}2p())") : "${indent}      2番目のカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}2p(),${pt}2p())!=0" :
                                          "${pt}pc(${pt}2p())!=0") : "${indent}      2番目のカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}2p(),${pt}2p())" :
                                          "${pt}pc(${pt}2p())") : "${indent}        2番目のカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(2番目のカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                push @out, $encode ? ")" : "";
              }
              $mode->{'nonzero2nd'}--;
              push @out, $encode ? ":" : "${indent}  さもなくば(2番目のパレットが0のとき)\n";
              $mode->{'zero2nd'}++;
              $mode->{'even2nd'}++;
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? ($dp ?
                                      "ls1(${pt}pc(tev(${pt}3p()),tev(${pt}3p())))!=0" :
                                      "ls1(${pt}pc(tev(${pt}3p())))!=0") : "${indent}    3番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                push @out, $encode ? "?" : "";
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "mix(mix(${pt}pc(tev(${pt}3p()),tev(${pt}3p())),${pt}pc(1,1)),0)" :
                                        "mix(mix(${pt}pc(tev(${pt}3p())),${pt}pc(1)),0)") : "${indent}      3番目のパレットを偶数化したパレットのカラーとパレット1のカラーを混ぜたカラーにさらにカラー0を混ぜたカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  push @out, $encode ? "mix(" : "";
                  push @out, $encode ? ($dp ?
                                        "mix(${pt}pc(tev(${pt}3p()),tev(${pt}3p())),${pt}pc(1,1))" :
                                        "mix(${pt}pc(tev(${pt}3p())),${pt}pc(1))") : "${indent}      3番目のパレットを偶数化したパレットのカラーとパレット1のカラーを混ぜたカラーにさらに\n";
                  push @out, $encode ? "," : "";
                  push @out, pass1 ("${indent}        ", $behind, $mode);
                  push @out, $encode ? ")" : "${indent}      を混ぜたカラー(0は黒)\n";
                }
                push @out, $encode ? ":" : "${indent}    さもなくば(3番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                {
                  push @out, $encode ? "(" : "";
                  push @out, $encode ? "ls1(${pt}3p())!=0" : "${indent}      3番目のパレットが奇数のとき\n";
                  push @out, $encode ? "?" : "";
                  $mode->{'odd3rd'}++;
                  $mode->{'nonzero3rd'}++;
                  if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(1,1)" :
                                          "${pt}pc(1)") : "${indent}        パレット1のカラー(0は黒)\n";
                  } else {  #グラフィックの奥にスプライト・テキストがある
                    {
                      push @out, $encode ? "(" : "";
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(1,1)!=0" :
                                            "${pt}pc(1)!=0") : "${indent}        パレット1のカラーが0でないとき\n";
                      push @out, $encode ? "?" : "";
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(1,1)" :
                                            "${pt}pc(1)") : "${indent}          パレット1のカラー\n";
                      push @out, $encode ? ":" : "${indent}        さもなくば(パレット1のカラーが0のとき)\n";
                      push @out, pass1 ("${indent}          ", $behind, $mode);
                      push @out, $encode ? ")" : "";
                    }
                  }
                  $mode->{'nonzero3rd'}--;
                  $mode->{'odd3rd'}--;
                  push @out, $encode ? ":" : "${indent}      さもなくば(3番目のパレットが偶数のとき)\n";
                  $mode->{'even3rd'}++;
                  if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}3p(),${pt}3p())" :
                                          "${pt}pc(${pt}3p())") : "${indent}        3番目のカラー(0は黒)\n";
                  } else {  #グラフィックの奥にスプライト・テキストがある
                    {
                      push @out, $encode ? "(" : "";
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(${pt}3p(),${pt}3p())!=0" :
                                            "${pt}pc(${pt}3p())!=0") : "${indent}        3番目のカラーが0でないとき\n";
                      push @out, $encode ? "?" : "";
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(${pt}3p(),${pt}3p())" :
                                            "${pt}pc(${pt}3p())") : "${indent}          3番目のカラー\n";
                      push @out, $encode ? ":" : "${indent}        さもなくば(3番目のカラーが0のとき)\n";
                      push @out, pass1 ("${indent}          ", $behind, $mode);
                      push @out, $encode ? ")" : "";
                    }
                  }
                  $mode->{'even3rd'}--;
                  push @out, $encode ? ")" : "";
                }
                push @out, $encode ? ")" : "";
              }
              $mode->{'even2nd'}--;
              $mode->{'zero2nd'}--;
              push @out, $encode ? ")" : "";
            }
            $mode->{'even1st'}--;
            $mode->{'zero1st'}--;
            push @out, $encode ? ")" : "";
          }
        } elsif ($g =~ /(?:E4)/) {  #グラフィック4プレーン。4番目はON。1番目と2番目と3番目はOFFのときパレット0とみなす
          {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${pt}1p()!=0" : "${indent}1番目のパレットが0でないとき\n";
            push @out, $encode ? "?" : "";
            $mode->{'nonzero1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? ($dp ?
                                    "ls1(${pt}pc(tev(${pt}1p()),tev(${pt}1p())))!=0" :
                                    "ls1(${pt}pc(tev(${pt}1p())))!=0") : "${indent}  1番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
              push @out, $encode ? "?" : "";
              if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                push @out, $encode ? ($dp ?
                                      "mix(mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q()))),0)" :
                                      "mix(mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q()))),0)") : "${indent}    1番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラーにさらにカラー0を混ぜたカラー(0は黒)\n";
              } else {  #グラフィックの奥にスプライト・テキストがある
                push @out, $encode ? "mix(" : "";
                push @out, $encode ? ($dp ?
                                      "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                      "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q())))") : "${indent}    1番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラーにさらに\n";
                push @out, $encode ? "," : "";
                push @out, pass1 ("${indent}      ", $behind, $mode);
                push @out, $encode ? ")" : "${indent}    を混ぜたカラー(0は黒)\n";
              }
              push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? "ls1(${pt}1p())!=0" : "${indent}    1番目のパレットが奇数のとき\n";
                push @out, $encode ? "?" : "";
                $mode->{'odd1st'}++;
                $mode->{'nonzero1st'}++;
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                        "${pt}pc(tod(${pt}2q()))") : "${indent}      2番目(ONとみなす)のパレットを奇数化したパレットのカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))!=0" :
                                          "${pt}pc(tod(${pt}2q()))!=0") : "${indent}      2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(tod(${pt}2q()),tod(${pt}2q()))" :
                                          "${pt}pc(tod(${pt}2q()))") : "${indent}        2番目(ONとみなす)のパレットを奇数化したパレットのカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(2番目(ONとみなす)のパレットを奇数化したパレットのカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                $mode->{'nonzero1st'}--;
                $mode->{'odd1st'}--;
                push @out, $encode ? ":" : "${indent}    さもなくば(1番目のパレットが偶数のとき)\n";
                $mode->{'even1st'}++;
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}1p(),${pt}1p())" :
                                        "${pt}pc(${pt}1p())") : "${indent}      1番目のカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}1p(),${pt}1p())!=0" :
                                          "${pt}pc(${pt}1p())!=0") : "${indent}      1番目のカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}1p(),${pt}1p())" :
                                          "${pt}pc(${pt}1p())") : "${indent}        1番目のカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(1番目のカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                $mode->{'even1st'}--;
                push @out, $encode ? ")" : "";
              }
              push @out, $encode ? ")" : "";
            }
            $mode->{'nonzero1st'}--;
            push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが0のとき)\n";
            $mode->{'zero1st'}++;
            $mode->{'even1st'}++;
            {
              push @out, $encode ? "(" : "";
              push @out, $encode ? "${pt}2p()!=0" : "${indent}  2番目のパレットが0でないとき\n";
              push @out, $encode ? "?" : "";
              $mode->{'nonzero2nd'}++;
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? ($dp ?
                                      "ls1(${pt}pc(tev(${pt}2p()),tev(${pt}2p())))!=0" :
                                      "ls1(${pt}pc(tev(${pt}2p())))!=0") : "${indent}    2番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                push @out, $encode ? "?" : "";
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "mix(mix(${pt}pc(tev(${pt}2p()),tev(${pt}2p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q()))),0)" :
                                        "mix(mix(${pt}pc(tev(${pt}2p())),${pt}pc(tod(${pt}2q()))),0)") : "${indent}      2番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラーにさらにカラー0を混ぜたカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  push @out, $encode ? "mix(" : "";
                  push @out, $encode ? ($dp ?
                                        "mix(${pt}pc(tev(${pt}2p()),tev(${pt}2p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                        "mix(${pt}pc(tev(${pt}2p())),${pt}pc(tod(${pt}2q())))") : "${indent}      2番目のパレットを偶数化したパレットのカラーと2番目(ONとみなす)のパレットを奇数化したパレットのカラーを混ぜたカラーにさらに\n";
                  push @out, $encode ? "," : "";
                  push @out, pass1 ("${indent}        ", $behind, $mode);
                  push @out, $encode ? ")" : "${indent}      を混ぜたカラー(0は黒)\n";
                }
                push @out, $encode ? ":" : "${indent}    さもなくば(2番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                  push @out, $encode ? ($dp ?
                                        "${pt}pc(${pt}2p(),${pt}2p())" :
                                        "${pt}pc(${pt}2p())") : "${indent}      2番目のカラー(0は黒)\n";
                } else {  #グラフィックの奥にスプライト・テキストがある
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}2p(),${pt}2p())!=0" :
                                          "${pt}pc(${pt}2p())!=0") : "${indent}      2番目のカラーが0でないとき\n";
                    push @out, $encode ? "?" : "";
                    push @out, $encode ? ($dp ?
                                          "${pt}pc(${pt}2p(),${pt}2p())" :
                                          "${pt}pc(${pt}2p())") : "${indent}        2番目のカラー\n";
                    push @out, $encode ? ":" : "${indent}      さもなくば(2番目のカラーが0のとき)\n";
                    push @out, pass1 ("${indent}        ", $behind, $mode);
                    push @out, $encode ? ")" : "";
                  }
                }
                push @out, $encode ? ")" : "";
              }
              $mode->{'nonzero2nd'}--;
              push @out, $encode ? ":" : "${indent}  さもなくば(2番目のパレットが0のとき)\n";
              $mode->{'zero2nd'}++;
              $mode->{'even2nd'}++;
              {
                push @out, $encode ? "(" : "";
                push @out, $encode ? "${pt}3p()!=0" : "${indent}    3番目のパレットが0でないとき\n";
                push @out, $encode ? "?" : "";
                $mode->{'nonzero3rd'}++;
                {
                  push @out, $encode ? "(" : "";
                  push @out, $encode ? ($dp ?
                                        "ls1(${pt}pc(tev(${pt}3p()),tev(${pt}3p())))!=0" :
                                        "ls1(${pt}pc(tev(${pt}3p())))!=0") : "${indent}      3番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                  push @out, $encode ? "?" : "";
                  if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                    push @out, $encode ? ($dp ?
                                          "mix(mix(${pt}pc(tev(${pt}3p()),tev(${pt}3p())),${pt}pc(1,1)),0)" :
                                          "mix(mix(${pt}pc(tev(${pt}3p())),${pt}pc(1)),0)") : "${indent}        3番目のパレットを偶数化したパレットのカラーとパレット1のカラーを混ぜたカラーにさらにカラー0を混ぜたカラー(0は黒)\n";
                  } else {  #グラフィックの奥にスプライト・テキストがある
                    push @out, $encode ? "mix(" : "";
                    push @out, $encode ? ($dp ?
                                          "mix(${pt}pc(tev(${pt}3p()),tev(${pt}3p())),${pt}pc(1,1))" :
                                          "mix(${pt}pc(tev(${pt}3p())),${pt}pc(1))") : "${indent}        3番目のパレットを偶数化したパレットのカラーとパレット1のカラーを混ぜたカラーにさらに\n";
                    push @out, $encode ? "," : "";
                    push @out, pass1 ("${indent}          ", $behind, $mode);
                    push @out, $encode ? ")" : "${indent}        を混ぜたカラー(0は黒)\n";
                  }
                  push @out, $encode ? ":" : "${indent}      さもなくば(3番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? "ls1(${pt}3p())!=0" : "${indent}        3番目のパレットが奇数のとき\n";
                    push @out, $encode ? "?" : "";
                    $mode->{'odd3rd'}++;
                    $mode->{'nonzero3rd'}++;
                    if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(1,1)" :
                                            "${pt}pc(1)") : "${indent}          パレット1のカラー(0は黒)\n";
                    } else {  #グラフィックの奥にスプライト・テキストがある
                      {
                        push @out, $encode ? "(" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(1,1)!=0" :
                                              "${pt}pc(1)!=0") : "${indent}          パレット1のカラーが0でないとき\n";
                        push @out, $encode ? "?" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(1,1)" :
                                              "${pt}pc(1)") : "${indent}            パレット1のカラー\n";
                        push @out, $encode ? ":" : "${indent}          さもなくば(パレット1のカラーが0のとき)\n";
                        push @out, pass1 ("${indent}            ", $behind, $mode);
                        push @out, $encode ? ")" : "";
                      }
                    }
                    $mode->{'nonzero3rd'}--;
                    $mode->{'odd3rd'}--;
                    push @out, $encode ? ":" : "${indent}        さもなくば(3番目のパレットが偶数のとき)\n";
                    $mode->{'even3rd'}++;
                    if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(${pt}3p(),${pt}3p())" :
                                            "${pt}pc(${pt}3p())") : "${indent}          3番目のカラー(0は黒)\n";
                    } else {  #グラフィックの奥にスプライト・テキストがある
                      {
                        push @out, $encode ? "(" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(${pt}3p(),${pt}3p())!=0" :
                                              "${pt}pc(${pt}3p())!=0") : "${indent}          3番目のカラーが0でないとき\n";
                        push @out, $encode ? "?" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(${pt}3p(),${pt}3p())" :
                                              "${pt}pc(${pt}3p())") : "${indent}            3番目のカラー\n";
                        push @out, $encode ? ":" : "${indent}          さもなくば(3番目のカラーが0のとき)\n";
                        push @out, pass1 ("${indent}            ", $behind, $mode);
                        push @out, $encode ? ")" : "";
                      }
                    }
                    $mode->{'even3rd'}--;
                    push @out, $encode ? ")" : "";
                  }
                  push @out, $encode ? ")" : "";
                }
                $mode->{'nonzero3rd'}--;
                push @out, $encode ? ":" : "${indent}    さもなくば(3番目のパレットが0のとき)\n";
                $mode->{'zero3rd'}++;
                $mode->{'even3rd'}++;
                {
                  push @out, $encode ? "(" : "";
                  push @out, $encode ? ($dp ?
                                        "ls1(${pt}pc(tev(${pt}4p()),tev(${pt}4p())))!=0" :
                                        "ls1(${pt}pc(tev(${pt}4p())))!=0") : "${indent}      4番目のパレットを偶数化したパレットのカラーが奇数のとき\n";
                  push @out, $encode ? "?" : "";
                  if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                    push @out, $encode ? ($dp ?
                                          "mix(mix(${pt}pc(tev(${pt}4p()),tev(${pt}4p())),${pt}pc(1,1)),0)" :
                                          "mix(mix(${pt}pc(tev(${pt}4p())),${pt}pc(1)),0)") : "${indent}        4番目のパレットを偶数化したパレットのカラーとパレット1のカラーを混ぜたカラーにさらにカラー0を混ぜたカラー(0は黒)\n";
                  } else {  #グラフィックの奥にスプライト・テキストがある
                    push @out, $encode ? "mix(" : "";
                    push @out, $encode ? ($dp ?
                                          "mix(${pt}pc(tev(${pt}4p()),tev(${pt}4p())),${pt}pc(1,1))" :
                                          "mix(${pt}pc(tev(${pt}4p())),${pt}pc(1))") : "${indent}        4番目のパレットを偶数化したパレットのカラーとパレット1のカラーを混ぜたカラーにさらに\n";
                    push @out, $encode ? "," : "";
                    push @out, pass1 ("${indent}          ", $behind, $mode);
                    push @out, $encode ? ")" : "${indent}        を混ぜたカラー(0は黒)\n";
                  }
                  push @out, $encode ? ":" : "${indent}      さもなくば(4番目のパレットを偶数化したパレットのカラーが偶数のとき)\n";
                  {
                    push @out, $encode ? "(" : "";
                    push @out, $encode ? "ls1(${pt}4p())!=0" : "${indent}        4番目のパレットが奇数のとき\n";
                    push @out, $encode ? "?" : "";
                    $mode->{'odd4th'}++;
                    $mode->{'nonzero4th'}++;
                    if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(1,1)" :
                                            "${pt}pc(1)") : "${indent}          パレット1のカラー(0は黒)\n";
                    } else {  #グラフィックの奥にスプライト・テキストがある
                      {
                        push @out, $encode ? "(" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(1,1)!=0" :
                                              "${pt}pc(1)!=0") : "${indent}          パレット1のカラーが0でないとき\n";
                        push @out, $encode ? "?" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(1,1)" :
                                              "${pt}pc(1)") : "${indent}            パレット1のカラー\n";
                        push @out, $encode ? ":" : "${indent}          さもなくば(パレット1のカラーが0のとき)\n";
                        push @out, pass1 ("${indent}            ", $behind, $mode);
                        push @out, $encode ? ")" : "";
                      }
                    }
                    $mode->{'nonzero4th'}--;
                    $mode->{'odd4th'}--;
                    push @out, $encode ? ":" : "${indent}        さもなくば(4番目のパレットが偶数のとき)\n";
                    $mode->{'even4th'}++;
                    if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
                      push @out, $encode ? ($dp ?
                                            "${pt}pc(${pt}4p(),${pt}4p())" :
                                            "${pt}pc(${pt}4p())") : "${indent}          4番目のカラー(0は黒)\n";
                    } else {  #グラフィックの奥にスプライト・テキストがある
                      {
                        push @out, $encode ? "(" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(${pt}4p(),${pt}4p())!=0" :
                                              "${pt}pc(${pt}4p())!=0") : "${indent}          4番目のカラーが0でないとき\n";
                        push @out, $encode ? "?" : "";
                        push @out, $encode ? ($dp ?
                                              "${pt}pc(${pt}4p(),${pt}4p())" :
                                              "${pt}pc(${pt}4p())") : "${indent}            4番目のカラー\n";
                        push @out, $encode ? ":" : "${indent}          さもなくば(4番目のカラーが0のとき)\n";
                        push @out, pass1 ("${indent}            ", $behind, $mode);
                        push @out, $encode ? ")" : "";
                      }
                    }
                    $mode->{'even4th'}--;
                    push @out, $encode ? ")" : "";
                  }
                  push @out, $encode ? ")" : "";
                }
                $mode->{'even3rd'}--;
                $mode->{'zero3rd'}--;
                push @out, $encode ? ")" : "";
              }
              $mode->{'even2nd'}--;
              $mode->{'zero2nd'}--;
              push @out, $encode ? ")" : "";
            }
            $mode->{'even1st'}--;
            $mode->{'zero1st'}--;
            push @out, $encode ? ")" : "";
          }
        } else {
          die $keyword;
        }
        $mode->{'xword'} = $xword;
        return @out;
      }

      if ($xword eq 'XHPT') {  #1番目のパレットが3以上の奇数のときそれを偶数化したパレットのカラーと奥のスプライト・テキストのカラーを混ぜる
        $mode->{'xword'} = '';
        push @out, $encode ? "(" : "";
        if (0) {
          push @out, $encode ? "${pt}1p()==0" : "${indent}1番目のパレットが0のとき\n";
          push @out, $encode ? "?" : "";
          $mode->{'zero1st'}++;
          $mode->{'even1st'}++;
          $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
          push @out, pass1 ("${indent}  ", $keyword, $mode);
          $mode->{'toeven'}--;
          $mode->{'even1st'}--;
          $mode->{'zero1st'}--;
          push @out, $encode ? ":" : "";
          push @out, $encode ? "${pt}1p()==1" : "${indent}1番目のパレットが1のとき\n";
          push @out, $encode ? "?" : "";
          $mode->{'nonzero1st'}++;
          $mode->{'one1st'}++;
          $mode->{'odd1st'}++;
          $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
          push @out, pass1 ("${indent}  ", $keyword, $mode);
          $mode->{'toeven'}--;
          $mode->{'odd1st'}--;
          $mode->{'one1st'}--;
          $mode->{'nonzero1st'}--;
        } else {
          $mode->{'zero1st'}++;
          $mode->{'even1st'}++;
          $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
          my @zero = pass1 ("${indent}  ", $keyword, $mode);
          $mode->{'toeven'}--;
          $mode->{'even1st'}--;
          $mode->{'zero1st'}--;
          $mode->{'nonzero1st'}++;
          $mode->{'one1st'}++;
          $mode->{'odd1st'}++;
          $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
          my @one = pass1 ("${indent}  ", $keyword, $mode);
          $mode->{'toeven'}--;
          $mode->{'odd1st'}--;
          $mode->{'one1st'}--;
          $mode->{'nonzero1st'}--;
          if (join ('', @zero) eq join ('', @one)) {  #0のときと1のときの手順が同じとき
            push @out, $encode ? "${pt}1p()<=1" : "${indent}1番目のパレットが1以下のとき\n";
            push @out, $encode ? "?" : "";
            push @out, @zero;
          } else {  #0のときと1のときの手順が違うとき
            push @out, $encode ? "${pt}1p()==0" : "${indent}1番目のパレットが0のとき\n";
            push @out, $encode ? "?" : "";
            push @out, @zero;
            push @out, $encode ? ":" : "";
            push @out, $encode ? "${pt}1p()==1" : "${indent}1番目のパレットが1のとき\n";
            push @out, $encode ? "?" : "";
            push @out, @one;
          }
        }
        push @out, $encode ? ":" : "";
        push @out, $encode ? "ls1(${pt}1p())==0" : "${indent}1番目のパレットが2以上の偶数のとき\n";
        push @out, $encode ? "?" : "";
        $mode->{'nonzero1st'}++;
        $mode->{'even1st'}++;
        $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
        push @out, pass1 ("${indent}  ", $keyword, $mode);
        $mode->{'toeven'}--;
        $mode->{'even1st'}--;
        $mode->{'nonzero1st'}--;
        push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが3以上の奇数のとき)\n";
        $mode->{'nonzero1st'}++;
        $mode->{'odd1st'}++;
        $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
        if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
          push @out, $encode ? ($dp ?
                                "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),0)" :
                                "mix(${pt}pc(tev(${pt}1p())),0)") : "${indent}  1番目のパレットを偶数化したパレットのカラーとカラー0を混ぜたカラー(0は黒)\n";
        } else {  #グラフィックの奥にスプライト・テキストがある
          push @out, $encode ? "mix(" : "";
          push @out, $encode ? ($dp ?
                                "${pt}pc(tev(${pt}1p()),tev(${pt}1p()))" :
                                "${pt}pc(tev(${pt}1p()))") : "${indent}  1番目のパレットを偶数化したパレットのカラーと\n";
          push @out, $encode ? "," : "";
          push @out, pass1 ("${indent}    ", $behind, $mode);
          push @out, $encode ? ")" : "${indent}  を混ぜたカラー(0は黒)\n";
        }
        $mode->{'toeven'}--;
        $mode->{'odd1st'}--;
        $mode->{'nonzero1st'}--;
        push @out, $encode ? ")" : "";
        $mode->{'xword'} = $xword;
        return @out;
      }

      if ($xword eq 'XHPG') {  #1番目のパレットが3以上の奇数のときそれを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜる
        $keyword =~ /(?:E1|E2|E3|E4|F1|F2)/ or die $keyword;  #512ドット65536色と1024ドットのとき1番目と2番目を混ぜるGは未対応
        $mode->{'xword'} = '';
        push @out, $encode ? "(" : "";
        if (0) {
          push @out, $encode ? "${pt}1p()==0" : "${indent}1番目のパレットが0のとき\n";
          push @out, $encode ? "?" : "";
          $mode->{'zero1st'}++;
          $mode->{'even1st'}++;
          $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
          push @out, pass1 ("${indent}  ", $keyword, $mode);
          $mode->{'toeven'}--;
          $mode->{'even1st'}--;
          $mode->{'zero1st'}--;
          push @out, $encode ? ":" : "";
          push @out, $encode ? "${pt}1p()==1" : "${indent}1番目のパレットが1のとき\n";
          push @out, $encode ? "?" : "";
          $mode->{'nonzero1st'}++;
          $mode->{'one1st'}++;
          $mode->{'odd1st'}++;
          $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
          push @out, pass1 ("${indent}  ", $keyword, $mode);
          $mode->{'toeven'}--;
          $mode->{'odd1st'}--;
          $mode->{'one1st'}--;
          $mode->{'nonzero1st'}--;
        } else {
          $mode->{'zero1st'}++;
          $mode->{'even1st'}++;
          $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
          my @zero = pass1 ("${indent}  ", $keyword, $mode);
          $mode->{'toeven'}--;
          $mode->{'even1st'}--;
          $mode->{'zero1st'}--;
          $mode->{'nonzero1st'}++;
          $mode->{'one1st'}++;
          $mode->{'odd1st'}++;
          $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
          my @one = pass1 ("${indent}  ", $keyword, $mode);
          $mode->{'toeven'}--;
          $mode->{'odd1st'}--;
          $mode->{'one1st'}--;
          $mode->{'nonzero1st'}--;
          if (join ('', @zero) eq join ('', @one)) {  #0のときと1のときの手順が同じとき
            push @out, $encode ? "${pt}1p()<=1" : "${indent}1番目のパレットが1以下のとき\n";
            push @out, $encode ? "?" : "";
            push @out, @zero;
          } else {  #0のときと1のときの手順が違うとき
            push @out, $encode ? "${pt}1p()==0" : "${indent}1番目のパレットが0のとき\n";
            push @out, $encode ? "?" : "";
            push @out, @zero;
            push @out, $encode ? ":" : "";
            push @out, $encode ? "${pt}1p()==1" : "${indent}1番目のパレットが1のとき\n";
            push @out, $encode ? "?" : "";
            push @out, @one;
          }
        }
        push @out, $encode ? ":" : "";
        push @out, $encode ? "ls1(${pt}1p())==0" : "${indent}1番目のパレットが2以上の偶数のとき\n";
        push @out, $encode ? "?" : "";
        $mode->{'nonzero1st'}++;
        $mode->{'even1st'}++;
        $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
        push @out, pass1 ("${indent}  ", $keyword, $mode);
        $mode->{'toeven'}--;
        $mode->{'even1st'}--;
        $mode->{'nonzero1st'}--;
        push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが3以上の奇数のとき)\n";
        $mode->{'nonzero1st'}++;
        $mode->{'odd1st'}++;
        $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
        if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
          if ($keyword =~ /(?:E2|F2)/) {  #2番目がON
            push @out, $encode ? ($dp ?
                                  "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2p()),tod(${pt}2p())))" :
                                  "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2p())))") : "${indent}  1番目のパレットを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜたカラー(0は黒)\n";
          } else {  #2番目がONとは限らない
            push @out, $encode ? ($dp ?
                                  "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                  "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q())))") : "${indent}  1番目のパレットを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜたカラー(0は黒)\n";
          }
        } else {  #グラフィックの奥にスプライト・テキストがある
          push @out, $encode ? "(" : "";
          if ($keyword =~ /(?:E2|F2)/) {  #2番目がON
            push @out, $encode ? ($dp ?
                                  "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2p()),tod(${pt}2p())))!=0" :
                                  "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2p())))!=0") : "${indent}  1番目のパレットを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜたカラーが0でないとき\n";
          } else {  #2番目がONとは限らない
            push @out, $encode ? ($dp ?
                                  "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))!=0" :
                                  "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q())))!=0") : "${indent}  1番目のパレットを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜたカラーが0でないとき\n";
          }
          push @out, $encode ? "?" : "";
          if ($keyword =~ /(?:E2|F2)/) {  #2番目がON
            push @out, $encode ? ($dp ?
                                  "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2p()),tod(${pt}2p())))" :
                                  "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2p())))") : "${indent}    1番目のパレットを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜたカラー\n";
          } else {  #2番目がONとは限らない
            push @out, $encode ? ($dp ?
                                  "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                  "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q())))") : "${indent}    1番目のパレットを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜたカラー\n";
          }
          push @out, $encode ? ":" : "${indent}  さもなくば(1番目のパレットを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜたカラーが0のとき)\n";
          push @out, pass1 ("${indent}    ", $behind, $mode);
          push @out, $encode ? ")" : "";
        }
        $mode->{'toeven'}--;
        $mode->{'odd1st'}--;
        $mode->{'nonzero1st'}--;
        push @out, $encode ? ")" : "";
        $mode->{'xword'} = $xword;
        return @out;
      }

      if ($xword eq 'XHPGT') {  #1番目のパレットが3以上の奇数のときそれを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜてさらに奥のスプライト・テキストのカラーを混ぜる
        $keyword =~ /(?:E1|E2|E3|E4|F1|F2)/ or die $keyword;  #512ドット65536色と1024ドットのとき1番目と2番目を混ぜるGは未対応
        $mode->{'xword'} = '';
        push @out, $encode ? "(" : "";
        if (0) {
          push @out, $encode ? "${pt}1p()==0" : "${indent}1番目のパレットが0のとき\n";
          push @out, $encode ? "?" : "";
          $mode->{'zero1st'}++;
          $mode->{'even1st'}++;
          $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
          push @out, pass1 ("${indent}  ", $keyword, $mode);
          $mode->{'toeven'}--;
          $mode->{'even1st'}--;
          $mode->{'zero1st'}--;
          push @out, $encode ? ":" : "";
          push @out, $encode ? "${pt}1p()==1" : "${indent}1番目のパレットが1のとき\n";
          push @out, $encode ? "?" : "";
          $mode->{'nonzero1st'}++;
          $mode->{'one1st'}++;
          $mode->{'odd1st'}++;
          $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
          push @out, pass1 ("${indent}  ", $keyword, $mode);
          $mode->{'toeven'}--;
          $mode->{'odd1st'}--;
          $mode->{'one1st'}--;
          $mode->{'nonzero1st'}--;
        } else {
          $mode->{'zero1st'}++;
          $mode->{'even1st'}++;
          $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
          my @zero = pass1 ("${indent}  ", $keyword, $mode);
          $mode->{'toeven'}--;
          $mode->{'even1st'}--;
          $mode->{'zero1st'}--;
          $mode->{'nonzero1st'}++;
          $mode->{'one1st'}++;
          $mode->{'odd1st'}++;
          $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
          my @one = pass1 ("${indent}  ", $keyword, $mode);
          $mode->{'toeven'}--;
          $mode->{'odd1st'}--;
          $mode->{'one1st'}--;
          $mode->{'nonzero1st'}--;
          if (join ('', @zero) eq join ('', @one)) {  #0のときと1のときの手順が同じとき
            push @out, $encode ? "${pt}1p()<=1" : "${indent}1番目のパレットが1以下のとき\n";
            push @out, $encode ? "?" : "";
            push @out, @zero;
          } else {  #0のときと1のときの手順が違うとき
            push @out, $encode ? "${pt}1p()==0" : "${indent}1番目のパレットが0のとき\n";
            push @out, $encode ? "?" : "";
            push @out, @zero;
            push @out, $encode ? ":" : "";
            push @out, $encode ? "${pt}1p()==1" : "${indent}1番目のパレットが1のとき\n";
            push @out, $encode ? "?" : "";
            push @out, @one;
          }
        }
        push @out, $encode ? ":" : "";
        push @out, $encode ? "ls1(${pt}1p())==0" : "${indent}1番目のパレットが2以上の偶数のとき\n";
        push @out, $encode ? "?" : "";
        $mode->{'nonzero1st'}++;
        $mode->{'even1st'}++;
        $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
        push @out, pass1 ("${indent}  ", $keyword, $mode);
        $mode->{'toeven'}--;
        $mode->{'even1st'}--;
        $mode->{'nonzero1st'}--;
        push @out, $encode ? ":" : "${indent}さもなくば(1番目のパレットが3以上の奇数のとき)\n";
        $mode->{'nonzero1st'}++;
        $mode->{'odd1st'}++;
        $mode->{'toeven'}++;  #グラフィックパレットを偶数化する
        if ($behind eq '') {  #グラフィックの奥にスプライト・テキストがない
          if ($keyword =~ /(?:E2|F2)/) {  #2番目がON
            push @out, $encode ? ($dp ?
                                  "mix(mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2p()),tod(${pt}2p()))),0)" :
                                  "mix(mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2p()))),0)") : "${indent}  1番目のパレットを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜたカラーにさらにカラー0を混ぜたカラー(0は黒)\n";
          } else {  #2番目がON
            push @out, $encode ? ($dp ?
                                  "mix(mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q()))),0)" :
                                  "mix(mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q()))),0)") : "${indent}  1番目のパレットを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜたカラーにさらにカラー0を混ぜたカラー(0は黒)\n";
          }
        } else {  #グラフィックの奥にスプライト・テキストがある
          push @out, $encode ? "mix(" : "";
          if ($keyword =~ /(?:E2|F2)/) {  #2番目がON
            push @out, $encode ? ($dp ?
                                  "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2p()),tod(${pt}2p())))" :
                                  "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2p())))") : "${indent}  1番目のパレットを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜたカラーにさらに\n";
          } else {  #2番目がONとは限らない
            push @out, $encode ? ($dp ?
                                  "mix(${pt}pc(tev(${pt}1p()),tev(${pt}1p())),${pt}pc(tod(${pt}2q()),tod(${pt}2q())))" :
                                  "mix(${pt}pc(tev(${pt}1p())),${pt}pc(tod(${pt}2q())))") : "${indent}  1番目のパレットを偶数化したパレットのカラーと2番目のパレットを奇数化したパレットのカラーを混ぜたカラーにさらに\n";
          }
          push @out, $encode ? "," : "";
          push @out, pass1 ("${indent}    ", $behind, $mode);
          push @out, $encode ? ")" : "${indent}  を混ぜたカラー(0は黒)\n";
        }
        $mode->{'toeven'}--;
        $mode->{'odd1st'}--;
        $mode->{'nonzero1st'}--;
        push @out, $encode ? ")" : "";
        $mode->{'xword'} = $xword;
        return @out;
      }

    }  #if 今回がグラフィック

  }  #if グラフィックが1プレーン以上ある

  if ($keyword eq '' || $keyword eq 'N') {  #何もないまたは表示なし
    push @out, $encode ? "0" : "${indent}カラー0(黒)\n";
    return @out;
  }

  if ($keyword =~ /^S/) {  #スプライト
    my $behind = $';
    if ($behind =~ /^T/) {  #スプライト→テキスト
      my $behind2 = $` . $';  #スプライトとテキストを除いた残り
      push @out, $encode ? "(" : "";
      push @out, $encode ? "ls4(spp())!=0||txp()==0" : "${indent}スプライトパレットの下位4bitが0でないまたはテキストパレットが0のとき\n";
      push @out, $encode ? "?" : "";
      #スプライトが代表。テキストを除外する
      if ($behind2 eq '') {  #何も残っていない
        push @out, $encode ? "spc(spp())" : "${indent}  スプライトカラー(0は黒)\n";
      } else {  #グラフィックが残っている
        push @out, $encode ? "(" : "";
        push @out, $encode ? "spc(spp())!=0" : "${indent}  スプライトカラーが0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "spc(spp())" : "${indent}    スプライトカラー\n";
        push @out, $encode ? ":" : "${indent}  さもなくば(スプライトカラーが0のとき)\n";
        push @out, pass1 ("${indent}    ", $behind2, $mode);
        push @out, $encode ? ")" : "";
      }
      push @out, $encode ? ":" : "${indent}さもなくば(スプライトパレットの下位4bitが0かつテキストパレットが0でないとき)\n";
      #テキストが代表。スプライトを除外する
      push @out, pass1 ("${indent}  ", $behind, $mode);
      push @out, $encode ? ")" : "";
    } elsif ($behind =~ /T/) {  #スプライト＞テキスト
      my $behind2 = $` . $';  #スプライトとテキストを除いた残り
      push @out, $encode ? "(" : "";
      push @out, $encode ? "ls4(spp())!=0||(spp()!=0&&txp()==0)" : "${indent}スプライトパレットの下位4bitが0でないまたは(スプライトパレットが0でないかつテキストパレットが0)のとき\n";
      push @out, $encode ? "?" : "";
      #スプライトが代表。テキストを除外する
      if ($behind2 eq '') {  #何も残っていない
        push @out, $encode ? "spc(spp())" : "${indent}  スプライトカラー(0は黒)\n";
      } else {  #グラフィックが残っている
        push @out, $encode ? "(" : "";
        push @out, $encode ? "spc(spp())!=0" : "${indent}  スプライトカラーが0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "spc(spp())" : "${indent}    スプライトカラー\n";
        push @out, $encode ? ":" : "${indent}  さもなくば(スプライトカラーが0のとき)\n";
        push @out, pass1 ("${indent}    ", $behind2, $mode);
        push @out, $encode ? ")" : "";
      }
      push @out, $encode ? ":" : "${indent}さもなくば(スプライトパレットが0または(スプライトパレットの下位4bitが0かつテキストパレットが0でない)のとき)\n";  #テキストが代表
      #テキストが代表。スプライトを除外する
      push @out, pass1 ("${indent}  ", $behind, $mode);
      push @out, $encode ? ")" : "";
    } elsif ($behind =~ /^t/) {  #スプライト→テキスト(OFF)
      my $behind2 = $';  #スプライトとテキスト(OFF)を除いた残り
      #スプライトが代表。テキスト(OFF)を除外する
      if ($behind2 eq '') {  #何も残っていない
        push @out, $encode ? "spc(spp())" : "${indent}スプライトカラー(0は黒)\n";
      } else {  #グラフィックが残っている
        push @out, $encode ? "(" : "";
        push @out, $encode ? "spc(spp())!=0" : "${indent}スプライトカラーが0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "spc(spp())" : "${indent}  スプライトカラー\n";
        push @out, $encode ? ":" : "${indent}さもなくば(スプライトカラーが0のとき)\n";
        push @out, pass1 ("${indent}  ", $behind2, $mode);
        push @out, $encode ? ")" : "";
      }
    } elsif ($behind =~ /t/) {  #スプライト＞テキスト(OFF)
      my $behind2 = $` . $';  #スプライトとテキスト(OFF)を除いた残り
      push @out, $encode ? "(" : "";
      push @out, $encode ? "spp()!=0" : "${indent}スプライトパレットが0でないとき\n";
      push @out, $encode ? "?" : "";
      #スプライトが代表。テキスト(OFF)を除外する
      if ($behind2 eq '') {  #何も残っていない
        push @out, $encode ? "spc(spp())" : "${indent}  スプライトカラー(0は黒)\n";
      } else {  #グラフィックが残っている
        push @out, $encode ? "(" : "";
        push @out, $encode ? "spc(spp())!=0" : "${indent}  スプライトカラーが0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "spc(spp())" : "${indent}    スプライトカラー\n";
        push @out, $encode ? ":" : "${indent}  さもなくば(スプライトカラーが0のとき)\n";
        push @out, pass1 ("${indent}    ", $behind2, $mode);
        push @out, $encode ? ")" : "";
      }
      push @out, $encode ? ":" : "${indent}さもなくば(スプライトパレットが0のとき)\n";
      #テキスト(OFF)が代表。スプライトを除外する
      push @out, pass1 ("${indent}  ", $behind, $mode);
      push @out, $encode ? ")" : "";
    } else {  #スプライトの奥にテキストがない
      if ($behind eq '') {  #スプライトの奥に何もない
        push @out, $encode ? "spc(spp())" : "${indent}スプライトカラー(0は黒)\n";
      } else {  #スプライトの奥にグラフィックがある
        push @out, $encode ? "(" : "";
        push @out, $encode ? "spc(spp())!=0" : "${indent}スプライトカラーが0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "spc(spp())" : "${indent}  スプライトカラー\n";
        push @out, $encode ? ":" : "${indent}さもなくば(スプライトカラーが0のとき)\n";
        push @out, pass1 ("${indent}  ", $behind, $mode);
        push @out, $encode ? ")" : "";
      }
    }
    return @out;
  }

  if ($keyword =~ /^s/) {  #スプライト(OFF)
    my $behind = $';
    $behind eq '' or die $keyword;  #スプライト(OFF)の奥に何かある
    push @out, $encode ? "spc(0)" : "${indent}スプライトパレット0のカラー(0は黒)\n";
    return @out;
  }

  if ($keyword =~ /^T/) {  #テキスト
    my $behind = $';
    if ($behind =~ /[Ss]/) {  #テキスト＞スプライト
      my $behind2 = $` . $';  #スプライトとテキストを除いた残り
      push @out, $encode ? "(" : "";
      push @out, $encode ? "txp()!=0" : "${indent}テキストパレットが0でないとき\n";
      push @out, $encode ? "?" : "";
      #テキストが代表。スプライトを除外する
      if ($behind2 eq '') {  #何も残っていない
        push @out, $encode ? "tpc(txp())" : "${indent}  テキストカラー(0は黒)\n";
      } else {  #グラフィックが残っている
        push @out, $encode ? "(" : "";
        push @out, $encode ? "tpc(txp())!=0" : "${indent}  テキストカラーが0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "tpc(txp())" : "${indent}    テキストカラー\n";
        push @out, $encode ? ":" : "${indent}  さもなくば(テキストカラーが0のとき)\n";
        push @out, pass1 ("${indent}    ", $behind2, $mode);  # $behind→$behind2 2023-01-20
        push @out, $encode ? ")" : "";
      }
      push @out, $encode ? ":" : "${indent}さもなくば(テキストパレットが0のとき)\n";
      #スプライトが代表。テキストを除外する
      push @out, pass1 ("${indent}  ", $behind, $mode);
      push @out, $encode ? ")" : "";
    } else {  #テキストの奥にスプライトがない
      if ($behind eq '') {  #テキストの奥に何もない
        push @out, $encode ? "tpc(txp())" : "${indent}テキストカラー(0は黒)\n";
      } else {  #テキストの奥にグラフィックがある
        push @out, $encode ? "(" : "";
        push @out, $encode ? "tpc(txp())!=0" : "${indent}テキストカラーが0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "tpc(txp())" : "${indent}  テキストカラー\n";
        push @out, $encode ? ":" : "${indent}さもなくば(テキストカラーが0のとき)\n";
        push @out, pass1 ("${indent}  ", $behind, $mode);
        push @out, $encode ? ")" : "";
      }
    }
    return @out;
  }

  if ($keyword =~ /^t/) {  #テキスト(OFF)
    my $behind = $';
    $behind eq '' or die $keyword;  #テキスト(OFF)の奥に何かある
    push @out, $encode ? "tpc(0)" : "${indent}テキストパレット0のカラー(0は黒)\n";
    return @out;
  }

  if ($keyword =~ /^(?:E1|F1|G|H|I|J)/) {  #グラフィック1プレーン。1番目はON、2番目と3番目と4番目はOFF
    my $behind = $';
    my $color1st = (($mode->{'zero1st'} && !$mode->{'toodd'}) ||
                    ($mode->{'one1st'} && $mode->{'toeven'}) ? $encode ? ($dp ?
                                                                          "${pt}pc(0,0)" :
                                                                          "${pt}pc(0)") : 'グラフィックパレット0のカラー' :
                    ($mode->{'zero1st'} && $mode->{'toodd'}) ||
                    ($mode->{'one1st'} && !$mode->{'toeven'}) ? $encode ? ($dp ?
                                                                           "${pt}pc(1,1)" :
                                                                           "${pt}pc(1)") : 'グラフィックパレット1のカラー' :
                    !$mode->{'even1st'} && $mode->{'toeven'} ? $encode ? ($dp ?
                                                                          "${pt}pc(tev(${pt}1p()),tev(${pt}1p()))" :
                                                                          "${pt}pc(tev(${pt}1p()))") : '1番目のパレットを偶数化したパレットのカラー' :
                    !$mode->{'odd1st'} && $mode->{'toodd'} ? $encode ? ($dp ?
                                                                        "${pt}pc(tod(${pt}1p()),tod(${pt}1p()))" :
                                                                        "${pt}pc(tod(${pt}1p()))") : '1番目のパレットを奇数化したパレットのカラー' :
                    $encode ? ($dp ?
                               "${pt}pc(${pt}1p(),${pt}1p())" :
                               "${pt}pc(${pt}1p())") : '1番目のカラー');
    if ($behind eq '') {
      push @out, $encode ? "${color1st}" : "${indent}${color1st}(0は黒)\n";
    } else {
      push @out, $encode ? "(" : "";
      push @out, $encode ? "${color1st}!=0" : "${indent}${color1st}が0でないとき\n";
      push @out, $encode ? "?" : "";
      push @out, $encode ? "${color1st}" : "${indent}  ${color1st}\n";
      push @out, $encode ? ":" : "${indent}さもなくば(${color1st}が0のとき)\n";
      push @out, pass1 ("${indent}  ", $behind, $mode);
      push @out, $encode ? ")" : "";
    }
    return @out;
  }

  if ($keyword =~ /^(?:E2|F2)/) {  #グラフィック2プレーン。2番目はON、3番目と4番目はOFF。1番目はOFFのときパレット0とみなす
    my $behind = $';
    my $palet1st = (($mode->{'zero1st'} && !$mode->{'toodd'}) ||
                    ($mode->{'one1st'} && $mode->{'toeven'}) ? $encode ? "0" : 'グラフィックパレット0' :
                    ($mode->{'zero1st'} && $mode->{'toodd'}) ||
                    ($mode->{'one1st'} && !$mode->{'toeven'}) ? $encode ? "1" : 'グラフィックパレット1' :
                    !$mode->{'even1st'} && $mode->{'toeven'} ? $encode ? "(tev(${pt}1p()))" : '1番目のパレットを偶数化したパレット' :
                    !$mode->{'odd1st'} && $mode->{'toodd'} ? $encode ? "(tod(${pt}1p()))" : '1番目のパレットを奇数化したパレット' :
                    $encode ? "${pt}1p()" : '1番目のパレット');
    my $color1st = (($mode->{'zero1st'} && !$mode->{'toodd'}) ||
                    ($mode->{'one1st'} && $mode->{'toeven'}) ? $encode ? ($dp ?
                                                                          "${pt}pc(0,0)" :
                                                                          "${pt}pc(0)") : 'グラフィックパレット0のカラー' :
                    ($mode->{'zero1st'} && $mode->{'toodd'}) ||
                    ($mode->{'one1st'} && !$mode->{'toeven'}) ? $encode ? ($dp ?
                                                                           "${pt}pc(1,1)" :
                                                                           "${pt}pc(1)") : 'グラフィックパレット1のカラー' :
                    !$mode->{'even1st'} && $mode->{'toeven'} ? $encode ? ($dp ?
                                                                          "${pt}pc(tev(${pt}1p()),tev(${pt}1p()))" :
                                                                          "${pt}pc(tev(${pt}1p()))") : '1番目のパレットを偶数化したパレットのカラー' :
                    !$mode->{'odd1st'} && $mode->{'toodd'} ? $encode ? ($dp ?
                                                                        "${pt}pc(tod(${pt}1p()),tod(${pt}1p()))" :
                                                                        "${pt}pc(tod(${pt}1p()))") : '1番目のパレットを奇数化したパレットのカラー' :
                    $encode ? ($dp ?
                               "${pt}pc(${pt}1p(),${pt}1p())" :
                               "${pt}pc(${pt}1p())") : '1番目のカラー');
    my $color2nd = (($mode->{'zero2nd'} && !$mode->{'toodd'}) ||
                    ($mode->{'one2nd'} && $mode->{'toeven'}) ? $encode ? ($dp ?
                                                                          "${pt}pc(0,0)" :
                                                                          "${pt}pc(0)") : 'グラフィックパレット0のカラー' :
                    ($mode->{'zero2nd'} && $mode->{'toodd'}) ||
                    ($mode->{'one2nd'} && !$mode->{'toeven'}) ? $encode ? ($dp ?
                                                                           "${pt}pc(1,1)" :
                                                                           "${pt}pc(1)") : 'グラフィックパレット1のカラー' :
                    !$mode->{'even2nd'} && $mode->{'toeven'} ? $encode ? ($dp ?
                                                                          "${pt}pc(tev(${pt}2p()),tev(${pt}2p()))" :
                                                                          "${pt}pc(tev(${pt}2p()))") : '2番目のパレットを偶数化したパレットのカラー' :
                    !$mode->{'odd2nd'} && $mode->{'toodd'} ? $encode ? ($dp ?
                                                                        "${pt}pc(tod(${pt}2p()),tod(${pt}2p()))" :
                                                                        "${pt}pc(tod(${pt}2p()))") : '2番目のパレットを奇数化したパレットのカラー' :
                    $encode ? ($dp ?
                               "${pt}pc(${pt}2p(),${pt}2p())" :
                               "${pt}pc(${pt}2p())") : '2番目のカラー');
    if ($mode->{'nonzero1st'}) {
      if ($behind eq '') {
        push @out, $encode ? "${color1st}" : "${indent}${color1st}(0は黒)\n";
      } else {
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${color1st}!=0" : "${indent}${color1st}が0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "${color1st}" : "${indent}  ${color1st}\n";
        push @out, $encode ? ":" : "${indent}さもなくば(${color1st}が0のとき)\n";
        push @out, pass1 ("${indent}  ", $behind, $mode);
        push @out, $encode ? ")" : "";
      }
    } elsif ($mode->{'zero1st'}) {
      if ($behind eq '') {
        push @out, $encode ? "${color2nd}" : "${indent}${color2nd}(0は黒)\n";
      } else {
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${color2nd}!=0" : "${indent}${color2nd}が0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "${color2nd}" : "${indent}  ${color2nd}\n";
        push @out, $encode ? ":" : "${indent}さもなくば(${color2nd}が0のとき)\n";
        push @out, pass1 ("${indent}  ", $behind, $mode);
        push @out, $encode ? ")" : "";
      }
    } else {
      push @out, $encode ? "(" : "";
      push @out, $encode ? "${palet1st}!=0" : "${indent}${palet1st}が0でないとき\n";
      push @out, $encode ? "?" : "";
      if ($behind eq '') {
        push @out, $encode ? "${color1st}" : "${indent}  ${color1st}(0は黒)\n";
      } else {
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${color1st}!=0" : "${indent}  ${color1st}が0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "${color1st}" : "${indent}    ${color1st}\n";
        push @out, $encode ? ":" : "${indent}  さもなくば(${color1st}が0のとき)\n";
        push @out, pass1 ("${indent}    ", $behind, $mode);
        push @out, $encode ? ")" : "";
      }
      push @out, $encode ? ":" : "${indent}さもなくば(${palet1st}が0のとき)\n";
      if ($behind eq '') {
        push @out, $encode ? "${color2nd}" : "${indent}  ${color2nd}(0は黒)\n";
      } else {
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${color2nd}!=0" : "${indent}  ${color2nd}が0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "${color2nd}" : "${indent}    ${color2nd}\n";
        push @out, $encode ? ":" : "${indent}  さもなくば(${color2nd}が0のとき)\n";
        push @out, pass1 ("${indent}    ", $behind, $mode);
        push @out, $encode ? ")" : "";
      }
      push @out, $encode ? ")" : "";
    }
    return @out;
  }

  if ($keyword =~ /^E3/) {  #グラフィック3プレーン。3番目はON、4番目はOFF。1番目と2番目はOFFのときパレット0とみなす
    my $behind = $';
    my $palet1st = (($mode->{'zero1st'} && !$mode->{'toodd'}) ||
                    ($mode->{'one1st'} && $mode->{'toeven'}) ? $encode ? "0" : 'グラフィックパレット0' :
                    ($mode->{'zero1st'} && $mode->{'toodd'}) ||
                    ($mode->{'one1st'} && !$mode->{'toeven'}) ? $encode ? "1" : 'グラフィックパレット1' :
                    !$mode->{'even1st'} && $mode->{'toeven'} ? $encode ? "(tev(${pt}1p()))" : '1番目のパレットを偶数化したパレット' :
                    !$mode->{'odd1st'} && $mode->{'toodd'} ? $encode ? "(tod(${pt}1p()))" : '1番目のパレットを奇数化したパレット' :
                    $encode ? "${pt}1p()" : '1番目のパレット');
    my $palet2nd = (($mode->{'zero2nd'} && !$mode->{'toodd'}) ||
                    ($mode->{'one2nd'} && $mode->{'toeven'}) ? $encode ? "0" : 'グラフィックパレット0' :
                    ($mode->{'zero2nd'} && $mode->{'toodd'}) ||
                    ($mode->{'one2nd'} && !$mode->{'toeven'}) ? $encode ? "1" : 'グラフィックパレット1' :
                    !$mode->{'even2nd'} && $mode->{'toeven'} ? $encode ? "(tev(${pt}2p()))" : '2番目のパレットを偶数化したパレット' :
                    !$mode->{'odd2nd'} && $mode->{'toodd'} ? $encode ? "(tod(${pt}2p()))" : '2番目のパレットを奇数化したパレット' :
                    $encode ? "${pt}2p()" : '2番目のパレット');
    my $color1st = (($mode->{'zero1st'} && !$mode->{'toodd'}) ||
                    ($mode->{'one1st'} && $mode->{'toeven'}) ? $encode ? ($dp ?
                                                                          "${pt}pc(0,0)" :
                                                                          "${pt}pc(0)") : 'グラフィックパレット0のカラー' :
                    ($mode->{'zero1st'} && $mode->{'toodd'}) ||
                    ($mode->{'one1st'} && !$mode->{'toeven'}) ? $encode ? ($dp ?
                                                                           "${pt}pc(1,1)" :
                                                                           "${pt}pc(1)") : 'グラフィックパレット1のカラー' :
                    !$mode->{'even1st'} && $mode->{'toeven'} ? $encode ? ($dp ?
                                                                          "${pt}pc(tev(${pt}1p()),tev(${pt}1p()))" :
                                                                          "${pt}pc(tev(${pt}1p()))") : '1番目のパレットを偶数化したパレットのカラー' :
                    !$mode->{'odd1st'} && $mode->{'toodd'} ? $encode ? ($dp ?
                                                                        "${pt}pc(tod(${pt}1p()),tod(${pt}1p()))" :
                                                                        "${pt}pc(tod(${pt}1p()))") : '1番目のパレットを奇数化したパレットのカラー' :
                    $encode ? ($dp ?
                               "${pt}pc(${pt}1p(),${pt}1p())" :
                               "${pt}pc(${pt}1p())") : '1番目のカラー');
    my $color2nd = (($mode->{'zero2nd'} && !$mode->{'toodd'}) ||
                    ($mode->{'one2nd'} && $mode->{'toeven'}) ? $encode ? ($dp ?
                                                                          "${pt}pc(0,0)" :
                                                                          "${pt}pc(0)") : 'グラフィックパレット0のカラー' :
                    ($mode->{'zero2nd'} && $mode->{'toodd'}) ||
                    ($mode->{'one2nd'} && !$mode->{'toeven'}) ? $encode ? ($dp ?
                                                                           "${pt}pc(1,1)" :
                                                                           "${pt}pc(1)") : 'グラフィックパレット1のカラー' :
                    !$mode->{'even2nd'} && $mode->{'toeven'} ? $encode ? ($dp ?
                                                                          "${pt}pc(tev(${pt}2p()),tev(${pt}2p()))" :
                                                                          "${pt}pc(tev(${pt}2p()))") : '2番目のパレットを偶数化したパレットのカラー' :
                    !$mode->{'odd2nd'} && $mode->{'toodd'} ? $encode ? ($dp ?
                                                                        "${pt}pc(tod(${pt}2p()),tod(${pt}2p()))" :
                                                                        "${pt}pc(tod(${pt}2p()))") : '2番目のパレットを奇数化したパレットのカラー' :
                    $encode ? ($dp ?
                               "${pt}pc(${pt}2p(),${pt}2p())" :
                               "${pt}pc(${pt}2p())") : '2番目のカラー');
    my $color3rd = (($mode->{'zero3rd'} && !$mode->{'toodd'}) ||
                    ($mode->{'one3rd'} && $mode->{'toeven'}) ? $encode ? ($dp ?
                                                                          "${pt}pc(0,0)" :
                                                                          "${pt}pc(0)") : 'グラフィックパレット0のカラー' :
                    ($mode->{'zero3rd'} && $mode->{'toodd'}) ||
                    ($mode->{'one3rd'} && !$mode->{'toeven'}) ? $encode ? ($dp ?
                                                                           "${pt}pc(1,1)" :
                                                                           "${pt}pc(1)") : 'グラフィックパレット1のカラー' :
                    !$mode->{'even3rd'} && $mode->{'toeven'} ? $encode ? ($dp ?
                                                                          "${pt}pc(tev(${pt}3p()),tev(${pt}3p()))" :
                                                                          "${pt}pc(tev(${pt}3p()))") : '3番目のパレットを偶数化したパレットのカラー' :
                    !$mode->{'odd3rd'} && $mode->{'toodd'} ? $encode ? ($dp ?
                                                                        "${pt}pc(tod(${pt}3p()),tod(${pt}3p()))" :
                                                                        "${pt}pc(tod(${pt}3p()))") : '3番目のパレットを奇数化したパレットのカラー' :
                    $encode ? ($dp ?
                               "${pt}pc(${pt}3p(),${pt}3p())" :
                               "${pt}pc(${pt}3p())") : '3番目のカラー');
    if ($mode->{'nonzero1st'}) {
      if ($behind eq '') {
        push @out, $encode ? "${color1st}" : "${indent}${color1st}(0は黒)\n";
      } else {
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${color1st}!=0" : "${indent}${color1st}が0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "${color1st}" : "${indent}  ${color1st}\n";
        push @out, $encode ? ":" : "${indent}さもなくば(${color1st}が0のとき)\n";
        push @out, pass1 ("${indent}  ", $behind, $mode);
        push @out, $encode ? ")" : "";
      }
    } elsif ($mode->{'zero1st'}) {
      if ($mode->{'nonzero2nd'}) {
        if ($behind eq '') {
          push @out, $encode ? "${color2nd}" : "${indent}${color2nd}(0は黒)\n";
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${color2nd}!=0" : "${indent}${color2nd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          push @out, $encode ? "${color2nd}" : "${indent}  ${color2nd}\n";
          push @out, $encode ? ":" : "${indent}さもなくば(${color2nd}が0のとき)\n";
          push @out, pass1 ("${indent}  ", $behind, $mode);
          push @out, $encode ? ")" : "";
        }
      } elsif ($mode->{'zero2nd'}) {
        if ($behind eq '') {
          push @out, $encode ? "${color3rd}" : "${indent}${color3rd}(0は黒)\n";
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${color3rd}!=0" : "${indent}${color3rd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          push @out, $encode ? "${color3rd}" : "${indent}  ${color3rd}\n";
          push @out, $encode ? ":" : "${indent}さもなくば(${color3rd}が0のとき)\n";
          push @out, pass1 ("${indent}  ", $behind, $mode);
          push @out, $encode ? ")" : "";
        }
      } else {
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${palet2nd}!=0" : "${indent}${palet2nd}が0でないとき\n";
        push @out, $encode ? "?" : "";
        if ($behind eq '') {
          push @out, $encode ? "${color2nd}" : "${indent}  ${color2nd}(0は黒)\n";
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${color2nd}!=0" : "${indent}  ${color2nd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          push @out, $encode ? "${color2nd}" : "${indent}    ${color2nd}\n";
          push @out, $encode ? ":" : "${indent}  さもなくば(${color2nd}が0のとき)\n";
          push @out, pass1 ("${indent}    ", $behind, $mode);
          push @out, $encode ? ")" : "";
        }
        push @out, $encode ? ":" : "${indent}さもなくば(${palet2nd}が0のとき)\n";
        if ($behind eq '') {
          push @out, $encode ? "${color3rd}" : "${indent}  ${color3rd}(0は黒)\n";
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${color3rd}!=0" : "${indent}  ${color3rd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          push @out, $encode ? "${color3rd}" : "${indent}    ${color3rd}\n";
          push @out, $encode ? ":" : "${indent}  さもなくば(${color3rd}が0のとき)\n";
          push @out, pass1 ("${indent}    ", $behind, $mode);
          push @out, $encode ? ")" : "";
        }
        push @out, $encode ? ")" : "";
      }
    } else {
      push @out, $encode ? "(" : "";
      push @out, $encode ? "${palet1st}!=0" : "${indent}${palet1st}が0でないとき\n";
      push @out, $encode ? "?" : "";
      if ($behind eq '') {
        push @out, $encode ? "${color1st}" : "${indent}  ${color1st}(0は黒)\n";
      } else {
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${color1st}!=0" : "${indent}  ${color1st}が0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "${color1st}" : "${indent}    ${color1st}\n";
        push @out, $encode ? ":" : "${indent}  さもなくば(${color1st}が0のとき)\n";
        push @out, pass1 ("${indent}    ", $behind, $mode);
        push @out, $encode ? ")" : "";
      }
      push @out, $encode ? ":" : "${indent}さもなくば(${palet1st}が0のとき)\n";
      if ($mode->{'nonzero2nd'}) {
        if ($behind eq '') {
          push @out, $encode ? "${color2nd}" : "${indent}  ${color2nd}(0は黒)\n";
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${color2nd}!=0" : "${indent}  ${color2nd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          push @out, $encode ? "${color2nd}" : "${indent}    ${color2nd}\n";
          push @out, $encode ? ":" : "${indent}  さもなくば(${color2nd}が0のとき)\n";
          push @out, pass1 ("${indent}    ", $behind, $mode);
          push @out, $encode ? ")" : "";
        }
      } elsif ($mode->{'zero2nd'}) {
        if ($behind eq '') {
          push @out, $encode ? "${color3rd}" : "${indent}  ${color3rd}(0は黒)\n";
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${color3rd}!=0" : "${indent}  ${color3rd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          push @out, $encode ? "${color3rd}" : "${indent}    ${color3rd}\n";
          push @out, $encode ? ":" : "${indent}  さもなくば(${color3rd}が0のとき)\n";
          push @out, pass1 ("${indent}    ", $behind, $mode);
          push @out, $encode ? ")" : "";
        }
      } else {
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${palet2nd}!=0" : "${indent}  ${palet2nd}が0でないとき\n";
        push @out, $encode ? "?" : "";
        if ($behind eq '') {
          push @out, $encode ? "${color2nd}" : "${indent}    ${color2nd}(0は黒)\n";
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${color2nd}!=0" : "${indent}    ${color2nd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          push @out, $encode ? "${color2nd}" : "${indent}      ${color2nd}\n";
          push @out, $encode ? ":" : "${indent}    さもなくば(${color2nd}が0のとき)\n";
          push @out, pass1 ("${indent}      ", $behind, $mode);
          push @out, $encode ? ")" : "";
        }
        push @out, $encode ? ":" : "${indent}  さもなくば(${palet2nd}が0のとき)\n";
        if ($behind eq '') {
          push @out, $encode ? "${color3rd}" : "${indent}    ${color3rd}(0は黒)\n";
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${color3rd}!=0" : "${indent}    ${color3rd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          push @out, $encode ? "${color3rd}" : "${indent}      ${color3rd}\n";
          push @out, $encode ? ":" : "${indent}    さもなくば(${color3rd}が0のとき)\n";
          push @out, pass1 ("${indent}      ", $behind, $mode);
          push @out, $encode ? ")" : "";
        }
        push @out, $encode ? ")" : "";
      }
      push @out, $encode ? ")" : "";
    }
    return @out;
  }

  if ($keyword =~ /^E4/) {  #グラフィック4プレーン。4番目はON。1番目と2番目と3番目はOFFのときパレット0とみなす
    my $behind = $';
    my $palet1st = (($mode->{'zero1st'} && !$mode->{'toodd'}) ||
                    ($mode->{'one1st'} && $mode->{'toeven'}) ? $encode ? "0" : 'グラフィックパレット0' :
                    ($mode->{'zero1st'} && $mode->{'toodd'}) ||
                    ($mode->{'one1st'} && !$mode->{'toeven'}) ? $encode ? "1" : 'グラフィックパレット1' :
                    !$mode->{'even1st'} && $mode->{'toeven'} ? $encode ? "(tev(${pt}1p()))" : '1番目のパレットを偶数化したパレット' :
                    !$mode->{'odd1st'} && $mode->{'toodd'} ? $encode ? "(tod(${pt}1p()))" : '1番目のパレットを奇数化したパレット' :
                    $encode ? "${pt}1p()" : '1番目のパレット');
    my $palet2nd = (($mode->{'zero2nd'} && !$mode->{'toodd'}) ||
                    ($mode->{'one2nd'} && $mode->{'toeven'}) ? $encode ? "0" : 'グラフィックパレット0' :
                    ($mode->{'zero2nd'} && $mode->{'toodd'}) ||
                    ($mode->{'one2nd'} && !$mode->{'toeven'}) ? $encode ? "1" : 'グラフィックパレット1' :
                    !$mode->{'even2nd'} && $mode->{'toeven'} ? $encode ? "(tev(${pt}2p()))" : '2番目のパレットを偶数化したパレット' :
                    !$mode->{'odd2nd'} && $mode->{'toodd'} ? $encode ? "(tod(${pt}2p()))" : '2番目のパレットを奇数化したパレット' :
                    $encode ? "${pt}2p()" : '2番目のパレット');
    my $palet3rd = (($mode->{'zero3rd'} && !$mode->{'toodd'}) ||
                    ($mode->{'one3rd'} && $mode->{'toeven'}) ? $encode ? "0" : 'グラフィックパレット0' :
                    ($mode->{'zero3rd'} && $mode->{'toodd'}) ||
                    ($mode->{'one3rd'} && !$mode->{'toeven'}) ? $encode ? "1" : 'グラフィックパレット1' :
                    !$mode->{'even3rd'} && $mode->{'toeven'} ? $encode ? "(tev(${pt}3p()))" : '3番目のパレットを偶数化したパレット' :
                    !$mode->{'odd3rd'} && $mode->{'toodd'} ? $encode ? "(tod(${pt}3p()))" : '3番目のパレットを奇数化したパレット' :
                    $encode ? "${pt}3p()" : '3番目のパレット');
    my $color1st = (($mode->{'zero1st'} && !$mode->{'toodd'}) ||
                    ($mode->{'one1st'} && $mode->{'toeven'}) ? $encode ? ($dp ?
                                                                          "${pt}pc(0,0)" :
                                                                          "${pt}pc(0)") : 'グラフィックパレット0のカラー' :
                    ($mode->{'zero1st'} && $mode->{'toodd'}) ||
                    ($mode->{'one1st'} && !$mode->{'toeven'}) ? $encode ? ($dp ?
                                                                           "${pt}pc(1,1)" :
                                                                           "${pt}pc(1)") : 'グラフィックパレット1のカラー' :
                    !$mode->{'even1st'} && $mode->{'toeven'} ? $encode ? ($dp ?
                                                                          "${pt}pc(tev(${pt}1p()),tev(${pt}1p()))" :
                                                                          "${pt}pc(tev(${pt}1p()))") : '1番目のパレットを偶数化したパレットのカラー' :
                    !$mode->{'odd1st'} && $mode->{'toodd'} ? $encode ? ($dp ?
                                                                        "${pt}pc(tod(${pt}1p()),tod(${pt}1p()))" :
                                                                        "${pt}pc(tod(${pt}1p()))") : '1番目のパレットを奇数化したパレットのカラー' :
                    $encode ? ($dp ?
                               "${pt}pc(${pt}1p(),${pt}1p())" :
                               "${pt}pc(${pt}1p())") : '1番目のカラー');
    my $color2nd = (($mode->{'zero2nd'} && !$mode->{'toodd'}) ||
                    ($mode->{'one2nd'} && $mode->{'toeven'}) ? $encode ? ($dp ?
                                                                          "${pt}pc(0,0)" :
                                                                          "${pt}pc(0)") : 'グラフィックパレット0のカラー' :
                    ($mode->{'zero2nd'} && $mode->{'toodd'}) ||
                    ($mode->{'one2nd'} && !$mode->{'toeven'}) ? $encode ? ($dp ?
                                                                           "${pt}pc(1,1)" :
                                                                           "${pt}pc(1)") : 'グラフィックパレット1のカラー' :
                    !$mode->{'even2nd'} && $mode->{'toeven'} ? $encode ? ($dp ?
                                                                          "${pt}pc(tev(${pt}2p()),tev(${pt}2p()))" :
                                                                          "${pt}pc(tev(${pt}2p()))") : '2番目のパレットを偶数化したパレットのカラー' :
                    !$mode->{'odd2nd'} && $mode->{'toodd'} ? $encode ? ($dp ?
                                                                        "${pt}pc(tod(${pt}2p()),tod(${pt}2p()))" :
                                                                        "${pt}pc(tod(${pt}2p()))") : '2番目のパレットを奇数化したパレットのカラー' :
                    $encode ? ($dp ?
                               "${pt}pc(${pt}2p(),${pt}2p())" :
                               "${pt}pc(${pt}2p())") : '2番目のカラー');
    my $color3rd = (($mode->{'zero3rd'} && !$mode->{'toodd'}) ||
                    ($mode->{'one3rd'} && $mode->{'toeven'}) ? $encode ? ($dp ?
                                                                          "${pt}pc(0,0)" :
                                                                          "${pt}pc(0)") : 'グラフィックパレット0のカラー' :
                    ($mode->{'zero3rd'} && $mode->{'toodd'}) ||
                    ($mode->{'one3rd'} && !$mode->{'toeven'}) ? $encode ? ($dp ?
                                                                           "${pt}pc(1,1)" :
                                                                           "${pt}pc(1)") : 'グラフィックパレット1のカラー' :
                    !$mode->{'even3rd'} && $mode->{'toeven'} ? $encode ? ($dp ?
                                                                          "${pt}pc(tev(${pt}3p()),tev(${pt}3p()))" :
                                                                          "${pt}pc(tev(${pt}3p()))") : '3番目のパレットを偶数化したパレットのカラー' :
                    !$mode->{'odd3rd'} && $mode->{'toodd'} ? $encode ? ($dp ?
                                                                        "${pt}pc(tod(${pt}3p()),tod(${pt}3p()))" :
                                                                        "${pt}pc(tod(${pt}3p()))") : '3番目のパレットを奇数化したパレットのカラー' :
                    $encode ? ($dp ?
                               "${pt}pc(${pt}3p(),${pt}3p())" :
                               "${pt}pc(${pt}3p())") : '3番目のカラー');
    my $color4th = (($mode->{'zero4th'} && !$mode->{'toodd'}) ||
                    ($mode->{'one4th'} && $mode->{'toeven'}) ? $encode ? ($dp ?
                                                                          "${pt}pc(0,0)" :
                                                                          "${pt}pc(0)") : 'グラフィックパレット0のカラー' :
                    ($mode->{'zero4th'} && $mode->{'toodd'}) ||
                    ($mode->{'one4th'} && !$mode->{'toeven'}) ? $encode ? ($dp ?
                                                                           "${pt}pc(1,1)" :
                                                                           "${pt}pc(1)") : 'グラフィックパレット1のカラー' :
                    !$mode->{'even4th'} && $mode->{'toeven'} ? $encode ? ($dp ?
                                                                          "${pt}pc(tev(${pt}4p()),tev(${pt}4p()))" :
                                                                          "${pt}pc(tev(${pt}4p()))") : '4番目のパレットを偶数化したパレットのカラー' :
                    !$mode->{'odd4th'} && $mode->{'toodd'} ? $encode ? ($dp ?
                                                                        "${pt}pc(tod(${pt}4p()),tod(${pt}4p()))" :
                                                                        "${pt}pc(tod(${pt}4p()))") : '4番目のパレットを奇数化したパレットのカラー' :
                    $encode ? ($dp ?
                               "${pt}pc(${pt}4p(),${pt}4p())" :
                               "${pt}pc(${pt}4p())") : '4番目のカラー');
    if ($mode->{'nonzero1st'}) {
      if ($behind eq '') {
        push @out, $encode ? "${color1st}" : "${indent}${color1st}(0は黒)\n";
      } else {
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${color1st}!=0" : "${indent}${color1st}が0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "${color1st}" : "${indent}  ${color1st}\n";
        push @out, $encode ? ":" : "${indent}さもなくば(${color1st}が0のとき)\n";
        push @out, pass1 ("${indent}  ", $behind, $mode);
        push @out, $encode ? ")" : "";
      }
    } elsif ($mode->{'zero1st'}) {
      if ($mode->{'nonzero2nd'}) {
        if ($behind eq '') {
          push @out, $encode ? "${color2nd}" : "${indent}${color2nd}(0は黒)\n";
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${color2nd}!=0" : "${indent}${color2nd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          push @out, $encode ? "${color2nd}" : "${indent}  ${color2nd}\n";
          push @out, $encode ? ":" : "${indent}さもなくば(${color2nd}が0のとき)\n";
          push @out, pass1 ("${indent}  ", $behind, $mode);
          push @out, $encode ? ")" : "";
        }
      } elsif ($mode->{'zero2nd'}) {
        if ($mode->{'nonzero3rd'}) {
          if ($behind eq '') {
            push @out, $encode ? "${color3rd}" : "${indent}${color3rd}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color3rd}!=0" : "${indent}${color3rd}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color3rd}" : "${indent}  ${color3rd}\n";
            push @out, $encode ? ":" : "${indent}さもなくば(${color3rd}が0のとき)\n";
            push @out, pass1 ("${indent}  ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
        } elsif ($mode->{'zero3rd'}) {
          if ($behind eq '') {
            push @out, $encode ? "${color4th}" : "${indent}${color4th}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color4th}!=0" : "${indent}${color4th}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color4th}" : "${indent}  ${color4th}\n";
            push @out, $encode ? ":" : "${indent}さもなくば(${color4th}が0のとき)\n";
            push @out, pass1 ("${indent}  ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${palet3rd}!=0" : "${indent}${palet3rd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          if ($behind eq '') {
            push @out, $encode ? "${color3rd}" : "${indent}  ${color3rd}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color3rd}!=0" : "${indent}  ${color3rd}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color3rd}" : "${indent}    ${color3rd}\n";
            push @out, $encode ? ":" : "${indent}  さもなくば(${color3rd}が0のとき)\n";
            push @out, pass1 ("${indent}    ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
          push @out, $encode ? ":" : "${indent}さもなくば(${palet3rd}が0のとき)\n";
          if ($behind eq '') {
            push @out, $encode ? "${color4th}" : "${indent}  ${color4th}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color4th}!=0" : "${indent}  ${color4th}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color4th}" : "${indent}    ${color4th}\n";
            push @out, $encode ? ":" : "${indent}  さもなくば(${color4th}が0のとき)\n";
            push @out, pass1 ("${indent}    ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
          push @out, $encode ? ")" : "";
        }
      } else {
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${palet2nd}!=0" : "${indent}${palet2nd}が0でないとき\n";
        push @out, $encode ? "?" : "";
        if ($behind eq '') {
          push @out, $encode ? "${color2nd}" : "${indent}  ${color2nd}(0は黒)\n";
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${color2nd}!=0" : "${indent}  ${color2nd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          push @out, $encode ? "${color2nd}" : "${indent}    ${color2nd}\n";
          push @out, $encode ? ":" : "${indent}  さもなくば(${color2nd}が0のとき)\n";
          push @out, pass1 ("${indent}    ", $behind, $mode);
          push @out, $encode ? ")" : "";
        }
        push @out, $encode ? ":" : "${indent}さもなくば(${palet2nd}が0のとき)\n";
        if ($mode->{'nonzero3rd'}) {
          if ($behind eq '') {
            push @out, $encode ? "${color3rd}" : "${indent}  ${color3rd}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color3rd}!=0" : "${indent}  ${color3rd}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color3rd}" : "${indent}    ${color3rd}\n";
            push @out, $encode ? ":" : "${indent}  さもなくば(${color3rd}が0のとき)\n";
            push @out, pass1 ("${indent}    ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
        } elsif ($mode->{'zero3rd'}) {
          if ($behind eq '') {
            push @out, $encode ? "${color4th}" : "${indent}  ${color4th}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color4th}!=0" : "${indent}  ${color4th}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color4th}" : "${indent}    ${color4th}\n";
            push @out, $encode ? ":" : "${indent}  さもなくば(${color4th}が0のとき)\n";
            push @out, pass1 ("${indent}    ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${palet3rd}!=0" : "${indent}  ${palet3rd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          if ($behind eq '') {
            push @out, $encode ? "${color3rd}" : "${indent}    ${color3rd}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color3rd}!=0" : "${indent}    ${color3rd}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color3rd}" : "${indent}      ${color3rd}\n";
            push @out, $encode ? ":" : "${indent}    さもなくば(${color3rd}が0のとき)\n";
            push @out, pass1 ("${indent}      ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
          push @out, $encode ? ":" : "${indent}  さもなくば(${palet3rd}が0のとき)\n";
          if ($behind eq '') {
            push @out, $encode ? "${color4th}" : "${indent}    ${color4th}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color4th}!=0" : "${indent}    ${color4th}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color4th}" : "${indent}      ${color4th}\n";
            push @out, $encode ? ":" : "${indent}    さもなくば(${color4th}が0のとき)\n";
            push @out, pass1 ("${indent}      ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
          push @out, $encode ? ")" : "";
        }
        push @out, $encode ? ")" : "";
      }
    } else {
      push @out, $encode ? "(" : "";
      push @out, $encode ? "${palet1st}!=0" : "${indent}${palet1st}が0でないとき\n";
      push @out, $encode ? "?" : "";
      if ($behind eq '') {
        push @out, $encode ? "${color1st}" : "${indent}  ${color1st}(0は黒)\n";
      } else {
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${color1st}!=0" : "${indent}  ${color1st}が0でないとき\n";
        push @out, $encode ? "?" : "";
        push @out, $encode ? "${color1st}" : "${indent}    ${color1st}\n";
        push @out, $encode ? ":" : "${indent}  さもなくば(${color1st}が0のとき)\n";
        push @out, pass1 ("${indent}    ", $behind, $mode);
        push @out, $encode ? ")" : "";
      }
      push @out, $encode ? ":" : "${indent}さもなくば(${palet1st}が0のとき)\n";
      if ($mode->{'nonzero2nd'}) {
        if ($behind eq '') {
          push @out, $encode ? "${color2nd}" : "${indent}  ${color2nd}(0は黒)\n";
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${color2nd}!=0" : "${indent}  ${color2nd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          push @out, $encode ? "${color2nd}" : "${indent}    ${color2nd}\n";
          push @out, $encode ? ":" : "${indent}  さもなくば(${color2nd}が0のとき)\n";
          push @out, pass1 ("${indent}    ", $behind, $mode);
          push @out, $encode ? ")" : "";
        }
      } elsif ($mode->{'zero2nd'}) {
        if ($mode->{'nonzero3rd'}) {
          if ($behind eq '') {
            push @out, $encode ? "${color3rd}" : "${indent}  ${color3rd}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color3rd}!=0" : "${indent}  ${color3rd}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color3rd}" : "${indent}    ${color3rd}\n";
            push @out, $encode ? ":" : "${indent}  さもなくば(${color3rd}が0のとき)\n";
            push @out, pass1 ("${indent}    ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
        } elsif ($mode->{'zero3rd'}) {
          if ($behind eq '') {
            push @out, $encode ? "${color4th}" : "${indent}  ${color4th}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color4th}!=0" : "${indent}  ${color4th}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color4th}" : "${indent}    ${color4th}\n";
            push @out, $encode ? ":" : "${indent}  さもなくば(${color4th}が0のとき)\n";
            push @out, pass1 ("${indent}    ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${palet3rd}!=0" : "${indent}  ${palet3rd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          if ($behind eq '') {
            push @out, $encode ? "${color3rd}" : "${indent}    ${color3rd}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color3rd}!=0" : "${indent}    ${color3rd}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color3rd}" : "${indent}      ${color3rd}\n";
            push @out, $encode ? ":" : "${indent}    さもなくば(${color3rd}が0のとき)\n";
            push @out, pass1 ("${indent}      ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
          push @out, $encode ? ":" : "${indent}  さもなくば(${palet3rd}が0のとき)\n";
          if ($behind eq '') {
            push @out, $encode ? "${color4th}" : "${indent}    ${color4th}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color4th}!=0" : "${indent}    ${color4th}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color4th}" : "${indent}      ${color4th}\n";
            push @out, $encode ? ":" : "${indent}    さもなくば(${color4th}が0のとき)\n";
            push @out, pass1 ("${indent}      ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
          push @out, $encode ? ")" : "";
        }
      } else {
        push @out, $encode ? "(" : "";
        push @out, $encode ? "${palet2nd}!=0" : "${indent}  ${palet2nd}が0でないとき\n";
        push @out, $encode ? "?" : "";
        if ($behind eq '') {
          push @out, $encode ? "${color2nd}" : "${indent}    ${color2nd}(0は黒)\n";
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${color2nd}!=0" : "${indent}    ${color2nd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          push @out, $encode ? "${color2nd}" : "${indent}      ${color2nd}\n";
          push @out, $encode ? ":" : "${indent}    さもなくば(${color2nd}が0のとき)\n";
          push @out, pass1 ("${indent}      ", $behind, $mode);
          push @out, $encode ? ")" : "";
        }
        push @out, $encode ? ":" : "${indent}  さもなくば(${palet2nd}が0のとき)\n";
        if ($mode->{'nonzero3rd'}) {
          if ($behind eq '') {
            push @out, $encode ? "${color3rd}" : "${indent}    ${color3rd}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color3rd}!=0" : "${indent}    ${color3rd}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color3rd}" : "${indent}      ${color3rd}\n";
            push @out, $encode ? ":" : "${indent}    さもなくば(${color3rd}が0のとき)\n";
            push @out, pass1 ("${indent}      ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
        } elsif ($mode->{'zero3rd'}) {
          if ($behind eq '') {
            push @out, $encode ? "${color4th}" : "${indent}    ${color4th}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color4th}!=0" : "${indent}    ${color4th}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color4th}" : "${indent}      ${color4th}\n";
            push @out, $encode ? ":" : "${indent}    さもなくば(${color4th}が0のとき)\n";
            push @out, pass1 ("${indent}      ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
        } else {
          push @out, $encode ? "(" : "";
          push @out, $encode ? "${palet3rd}!=0" : "${indent}    ${palet3rd}が0でないとき\n";
          push @out, $encode ? "?" : "";
          if ($behind eq '') {
            push @out, $encode ? "${color3rd}" : "${indent}      ${color3rd}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color3rd}!=0" : "${indent}      ${color3rd}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color3rd}" : "${indent}        ${color3rd}\n";
            push @out, $encode ? ":" : "${indent}      さもなくば(${color3rd}が0のとき)\n";
            push @out, pass1 ("${indent}        ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
          push @out, $encode ? ":" : "${indent}    さもなくば(${palet3rd}が0のとき)\n";
          if ($behind eq '') {
            push @out, $encode ? "${color4th}" : "${indent}      ${color4th}(0は黒)\n";
          } else {
            push @out, $encode ? "(" : "";
            push @out, $encode ? "${color4th}!=0" : "${indent}      ${color4th}が0でないとき\n";
            push @out, $encode ? "?" : "";
            push @out, $encode ? "${color4th}" : "${indent}        ${color4th}\n";
            push @out, $encode ? ":" : "${indent}      さもなくば(${color4th}が0のとき)\n";
            push @out, pass1 ("${indent}        ", $behind, $mode);
            push @out, $encode ? ")" : "";
          }
          push @out, $encode ? ")" : "";
        }
        push @out, $encode ? ")" : "";
      }
      push @out, $encode ? ")" : "";
    }
    return @out;
  }

  die $keyword;
}  #sub pass1



#================================================================================
#ノードツリー
my $NT_INT            =  0;  #0           整数
my $NT_ID             =  1;  #a           識別子
my $NT_PARENTHESIS    =  2;  #(a)         括弧。インデント用。パーサでは入力できない。new_parenthesisで作る
my $NT_CASTCHAR       =  3;  #(char) (a)  キャスト。パーサでは入力できない。new_castcharで作る
my $NT_ARRAYACCESS    =  4;  #a[b]        配列アクセス
my $NT_FUNCTION       =  5;  #a(b,c)      関数呼び出し
my $NT_UNARY          =  6;  #!a          単項
my $NT_MULTIPLICATION =  7;  #a*b         乗除算
my $NT_ADDITION       =  8;  #a+b         加減算
my $NT_SHIFT          =  9;  #a<<b        シフト
my $NT_COMPARISON     = 10;  #a<b         比較
my $NT_EQUALITY       = 11;  #a==b        等価
my $NT_BITWISEAND     = 12;  #a&b         ビットAND
my $NT_BITWISEEOR     = 13;  #a^b         ビットEOR
my $NT_BITWISEIOR     = 14;  #a|b         ビットIOR
my $NT_LOGICALAND     = 15;  #a&&b        論理AND
my $NT_LOGICALIOR     = 16;  #a||b        論理IOR
my $NT_CONDITION      = 17;  #a?b:c       条件
my $NT_ASSIGNMENT     = 18;  #b=a         代入

my %NODE_TYPE_HASH = (
  NT_INT => $NT_INT,
  NT_ID => $NT_ID,
  NT_ARRAYACCESS => $NT_ARRAYACCESS,
  NT_FUNCTION => $NT_FUNCTION,
  NT_UNARY => $NT_UNARY,
  NT_MULTIPLICATION => $NT_MULTIPLICATION,
  NT_ADDITION => $NT_ADDITION,
  NT_SHIFT => $NT_SHIFT,
  NT_COMPARISON => $NT_COMPARISON,
  NT_EQUALITY => $NT_EQUALITY,
  NT_BITWISEAND => $NT_BITWISEAND,
  NT_BITWISEEOR => $NT_BITWISEEOR,
  NT_BITWISEIOR => $NT_BITWISEIOR,
  NT_LOGICALAND => $NT_LOGICALAND,
  NT_LOGICALIOR => $NT_LOGICALIOR,
  NT_CONDITION => $NT_CONDITION,
  NT_ASSIGNMENT => $NT_ASSIGNMENT
  );
my @NODE_TYPE_LIST = ();
foreach my $key (keys %NODE_TYPE_HASH) {
  $NODE_TYPE_LIST[$NODE_TYPE_HASH{$key}] = $key;
}

#  入れ換え
#    古いノードにある親ノードへのポインタを新しいノードにコピーする
#    親ノードの子リストにある古いノードへのポインタを新しいノードへのポインタに置き換える
#    古いノードは書き換えない
sub replace_node {
  my ($from_node, $to_node) = @_;
  my $parent = $from_node->{'parent'};
  $to_node->{'parent'} = $parent;
  if ($parent) {
    my $children = $parent->{'children'};
    for (my $i = 0; $i < @$children; $i++) {
      if ($children->[$i] eq $from_node) {
        $children->[$i] = $to_node;
        last;
      }
    }
  }
  $to_node;
}

#  チェック
my @NODE_KEYS = qw(children evaluate number operator parent text tocode tostring type varmap);
my %NODE_KEYS = map { $_ => 1 } @NODE_KEYS;
sub check_node {
  my ($node) = @_;
  check_node_sub ($node, {});
}
sub check_node_sub {
  my ($node, $history) = @_;
  defined $node or die "node is not specified";
  #  同じノードが2回以上使われていないか確認する
  exists $history->{$node} and print_node ($node), die "node appears twice";
  $history->{$node} = $node;
  #  フィールドが設定されているか確認する
  foreach my $key (@NODE_KEYS) {
    defined $node->{$key} or print_node ($node), die "$key is not specified";
  }
  #  未知のフィールドがないか確認する
  foreach my $key (keys %$node) {
    exists $NODE_KEYS{$key} or print_node ($node), die "unknown field $key";
  }
  #  type毎のチェック
  my $type = $node->{'type'};
  my $children = $node->{'children'};
  if ($type == $NT_INT) {
    @$children == 0 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_ID) {
    @$children == 0 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_PARENTHESIS) {
    @$children == 1 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_CASTCHAR) {
    @$children == 1 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_ARRAYACCESS) {
    @$children == 2 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_FUNCTION) {
    1 <= @$children or print_node ($node), die "wrong length of children";
    $children->[0]->{'type'} == $NT_ID or print_node ($node), die "wrong type of a child";  #a(b,c)のaは識別子に限る
  } elsif ($type == $NT_UNARY) {
    @$children == 1 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_MULTIPLICATION) {
    @$children == 2 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_ADDITION) {
    @$children == 2 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_SHIFT) {
    @$children == 2 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_COMPARISON) {
    @$children == 2 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_EQUALITY) {
    @$children == 2 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_BITWISEAND) {
    @$children == 2 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_BITWISEEOR) {
    @$children == 2 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_BITWISEIOR) {
    @$children == 2 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_LOGICALAND) {
    @$children == 2 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_LOGICALIOR) {
    @$children == 2 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_CONDITION) {
    @$children == 3 or print_node ($node), die "wrong length of children";
  } elsif ($type == $NT_ASSIGNMENT) {
    @$children == 2 or print_node ($node), die "wrong length of children";
    $children->[1]->{'type'} == $NT_ID ||
      $children->[1]->{'type'} == $NT_ARRAYACCESS or print_node ($node), die "wrong type of a child";  #b=aのaは識別子または配列に限る
  } else {
    print_node ($node), die "unknown type";
  }
  #  parentとchildrenの整合を確認する。子ノードを再帰的に処理する
  foreach my $child (@{$node->{'children'}}) {
    $child->{'parent'} eq $node or print_node ($node), print_node ($child), die "parent children mismatch";
    check_node ($child, $history);
  }
}

#  表示
sub print_node {
  my ($node) = @_;
  print "----------------------------------------\n";
  my %map = map { $_ => 1 } @NODE_KEYS, keys %$node;  #必要なフィールドと存在するフィールド
  foreach my $key (sort { $a cmp $b } keys %map) {
    if (defined $node->{$key}) {
      my $value = $node->{$key};
      if ('ARRAY' eq ref $value) {
        my $length = @$value;
        print "$key = array ($length)\n";
      } elsif ('HASH' eq ref $value) {
        my $length = keys %$value;
        print "$key = hash ($length)\n";
      } elsif ('CODE' eq ref $value) {
        print "$key = code\n";
      } elsif ('' ne ref $value) {
        my $ref = ref $value;
        print "$key = $ref $value\n";
      } elsif ($key eq 'type') {
        if (int ($value) == $value && 0 <= $value && $value < @NODE_TYPE_LIST) {
          print "$key = $value ($NODE_TYPE_LIST[$value])\n";
        } else {
          print "$key = $value (???)\n";
        }
      } elsif ($key eq 'varmap') {
        my $s = join ',', varr ($value);
        print "$key = ($s)\n";
      } else {
        print "$key = $value\n";
      }
    } else {
      print "$key = NOTSPECIFIED\n";
    }
  }
}

#  ダンプ
sub dump_node {
  my ($node, $depth) = @_;
  defined $depth or $depth = 0;
  my $indent = '  ' x $depth;
  foreach my $key (sort { $a cmp $b } keys %$node) {
    my $value = $node->{$key};
    if ('ARRAY' eq ref $value) {
      foreach my $index (0 .. $#$value) {
        if ($key eq 'children') {
          print "$indent${key}[$index] = *\n";
          dump_node ($value->[$index], $depth + 1);
        } else {
          print "$indent${key}[$index] = $value->[$index]\n";
        }
      }
    } elsif ('HASH' eq ref $value) {
      if ($key eq 'parent') {
        print "$indent$key = *\n";
      } else {
        dump_node ($value, $depth + 1);
      }
    } elsif ('CODE' eq ref $value) {
      print "$indent$key = *\n";
    } else {
      print "$indent$key = $value\n";
    }
  }
}  #sub dump_node



#================================================================================
#バイナリベクタ
my $VLEN = 256;

sub vand {
  my ($x, $y) = @_;
  for (my $i = 0; $i <= $VLEN - 1; $i++) {
    vec ($x, $i, 1) &= vec ($y, $i, 1);
  }
  $x;
}

sub varr {
  my ($x) = @_;
  my @a = ();
  for (my $i = 0; $i <= $VLEN - 1; $i++) {
    vec ($x, $i, 1) and push @a, $i;
  }
  @a;
}

sub vclr {
  my ($x, @a) = @_;
  foreach my $i (@a) {
    0 <= $i && $i <= $VLEN - 1 or die;
    vec ($x, $i, 1) = 0;
  }
  $x;
}

sub vcmp {
  my ($x, $y) = @_;
  for (my $i = $VLEN - 1; $i >= 0; $i--) {
    my $t = vec ($x, $i, 1) <=> vec ($y, $i, 1);
    $t and return $t;
  }
  0;
}

sub vffo {
  my ($x) = @_;
  for (my $i = $VLEN - 1; $i >= 0; $i--) {
    vec ($x, $i, 1) and return $i;
  }
  -1;
}

sub vflo {
  my ($x) = @_;
  for (my $i = 0; $i <= $VLEN - 1; $i++) {
    vec ($x, $i, 1) and return $i;
  }
  -1;
}

sub vget {
  my ($x, $i) = @_;
  0 <= $i && $i <= $VLEN - 1 or die;
  vec ($x, $i, 1);
}

sub vior {
  my ($x, $y) = @_;
  for (my $i = 0; $i <= $VLEN - 1; $i++) {
    vec ($x, $i, 1) |= vec ($y, $i, 1);
  }
  $x;
}

sub vnew {
  pack 'N' . ($VLEN + 31 >> 5);
}

sub vnot {
  my ($x) = @_;
  for (my $i = 0; $i <= $VLEN - 1; $i++) {
    vec ($x, $i, 1) ^= 1;
  }
  $x;
}

sub vnul {
  my ($x) = @_;
  for (my $i = 0; $i <= $VLEN - 1; $i++) {
    vec ($x, $i, 1) and return 0;
  }
  1;
}

sub vpop {
  my ($x) = @_;
  my $n = 0;
  for (my $i = 0; $i <= $VLEN - 1; $i++) {
    vec ($x, $i, 1) and $n++;
  }
  $n;
}

sub vrev {
  my ($x) = @_;
  for (my $i = 0; $i <= $VLEN - 1 >> 1; $i++) {
    my $j = $VLEN - 1 - $i;
    my $t = vec ($x, $i, 1);
    vec ($x, $i, 1) = vec ($x, $j, 1);
    vec ($x, $j, 1) = $t;
  }
  $x;
}

sub vset {
  my ($x, @a) = @_;
  foreach my $i (@a) {
    0 <= $i && $i <= $VLEN - 1 or die;
    vec ($x, $i, 1) = 1;
  }
  $x;
}

sub vxor {
  my ($x, $y) = @_;
  for (my $i = 0; $i <= $VLEN - 1; $i++) {
    vec ($x, $i, 1) ^= vec ($y, $i, 1);
  }
  $x;
}



#================================================================================
#パス2
#  中間コード1をノードツリーに変換する
#  実装されていない文法を使おうとしたときは確実にエラーにすること
sub pass2 {
  my ($s0) = @_;
  my ($node, $s) = parse_assignment ($s0, $s0, '');
  $s eq '' or parse_error ("syntax error", $s, $s0);
  $node;
}

#  エラー表示
sub parse_error {
  my ($message, $s, $s0) = @_;
  my $t = ' ' x (length ($s0) - length ($s));
  die "$message\n$s0\n$t^\n";
}

#テキストを出力する
#  textを出力して長さをcolumnに加える
sub put_text {
  my ($text, $status) = @_;
  if ($status->{'column'} < 0) {  #改行済みだがインデントされていない
    push @{$status->{'buffer'}}, ' ' x $status->{'indent'};
    $status->{'column'} = $status->{'indent'};
  }
  push @{$status->{'buffer'}}, $text;
  $status->{'column'} += length $text;
}

#左括弧を出力する
#  textを出力して長さをcolumnに加える
#  indentを保存して現在のcolumnを新しいindentにする
sub put_left {
  my ($text, $status) = @_;
  put_text ($text, $status);
  push @{$status->{'stack'}}, $status->{'indent'};
  $status->{'indent'} = $status->{'column'};
}

#右括弧を出力する
#  textを出力して長さをcolumnに加える
#  indentを復元する
sub put_right {
  my ($text, $status) = @_;
  put_text ($text, $status);
  $status->{'indent'} = pop @{$status->{'stack'}};
}

#改行を出力する
#  textを出力して長さをcolumnに加える
#  columnを-1にする
sub put_newline {
  my ($text, $status) = @_;
  put_text ($text, $status);
  $status->{'column'} = -1;
}

sub new_node {
  my (%map) = @_;
  exists $map{'evaluate'} or die "evaluate is not specified";
  exists $map{'tocode'} or die "tocode is not specified";
  exists $map{'tostring'} or die "tostring is not specified";
  exists $map{'type'} or die "type is not specified";
  my $node = {
    children => $map{'children'} // [],
    evaluate => $map{'evaluate'},
    number => $map{'number'} // 0,
    operator => $map{'operator'} // '',
    parent => $map{'parent'} // '',
    text => $map{'text'} // '',
    tocode => $map{'tocode'},
    tostring => $map{'tostring'},
    type => $map{'type'},
    varmap => $map{'varmap'} // vnew ()
    };
  foreach my $child (@{$node->{'children'}}) {
    $child->{'parent'} = $node;
  }
  &{$node->{'tostring'}} ($node);  #textを更新する
  $node;
}

#  基本
sub int_tocode {
  my ($this, $status) = @_;
  put_text ($this->{'text'}, $status);
}
sub int_tostring {
  my ($this) = @_;
  $this->{'text'};
}
sub int_evaluate {
  my ($this, $status) = @_;
  new_node (evaluate => *int_evaluate,
            text => $this->{'text'},
            tocode => *int_tocode,
            tostring => *int_tostring,
            type => $NT_INT);
}
sub new_int {
  my ($value) = @_;
  new_node (evaluate => *int_evaluate,
            text => $value,
            tocode => *int_tocode,
            tostring => *int_tostring,
            type => $NT_INT);
}
sub id_tocode {
  my ($this, $status) = @_;
  $status->{"id_$this->{'text'}"} = 1;
  put_text ($this->{'text'}, $status);
}
sub id_tostring {
  my ($this) = @_;
  $this->{'text'};
}
sub id_evaluate {
  my ($this, $status) = @_;
  new_node (evaluate => *id_evaluate,
            text => $this->{'text'},
            tocode => *id_tocode,
            tostring => *id_tostring,
            type => $NT_ID);
}
sub new_id {
  my ($name) = @_;
  new_node (evaluate => *id_evaluate,
            text => $name,
            tocode => *id_tocode,
            tostring => *id_tostring,
            type => $NT_ID);
}
sub parenthesis_tocode {
  my ($this, $status) = @_;
  my $x = $this->{'children'}->[0];
  put_left ('(', $status);
  &{$x->{'tocode'}} ($x, $status);
  put_right (')', $status);
}
sub parenthesis_tostring {
  my ($this) = @_;
  my ($child0) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  $this->{'text'} = "(${text0})";
}
sub new_parenthesis {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            tocode => *parenthesis_tocode,
            tostring => *parenthesis_tostring,
            type => $NT_PARENTHESIS);
}
sub castchar_tocode {
  my ($this, $status) = @_;
  my $x = $this->{'children'}->[0];
  put_left ('(char) (', $status);
  &{$x->{'tocode'}} ($x, $status);
  put_right (')', $status);
}
sub castchar_tostring {
  my ($this) = @_;
  my ($child0) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  $this->{'text'} = "(char) (${text0})";
}
sub new_castchar {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            tocode => *castchar_tocode,
            tostring => *castchar_tostring,
            type => $NT_CASTCHAR);
}
sub parse_primitive {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  if ($s =~ /^\s*([-+]?\d+)/) {  #整数
    my $text = $1;
    $s = $';
    $node = new_int ($text);
    $node->{'parent'} = $parent;
  } elsif ($s =~ /^\s*([A-Z_a-z][\.0-9A-Z_a-z]*)/) {  #識別子
    my $text = $1;
    $s = $';
    $node = new_id ($text);
    $node->{'parent'} = $parent;
  } elsif ($s =~ /^\s*(\()/) {  #括弧
    $s = $';
    ($node, $s) = parse_assignment ($s, $s0, $parent);
    $s =~ /^\s*(\))/ or parse_error (") expected", $s, $s0);
    $s = $';
  } else {
    parse_error ("syntax error", $s, $s0);
  }
  ($node, $s);
}

sub evaluate_operator {
  my ($this, $status) = @_;
  new_node (children => [map { &{$_->{'evaluate'}} ($_, $status) } @{$this->{'children'}}],
            evaluate => $this->{'evaluate'},
            number => $this->{'number'},
            operator => $this->{'operator'},
            #parent => '',
            #text => '',
            tocode => $this->{'tocode'},
            tostring => $this->{'tostring'},
            type => $this->{'type'},
            varmap => $this->{'varmap'});
}

#  配列
sub arrayaccess_tocode {
  my ($this, $status) = @_;
  my $x = $this->{'children'}->[0];
  my $y = $this->{'children'}->[1];
  &{$x->{'tocode'}} ($x, $status);
  put_left ('[', $status);
  &{$y->{'tocode'}} ($y, $status);
  put_right (']', $status);
}
sub arrayaccess_tostring {
  my ($this) = @_;
  my ($child0, $child1) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  my $text1 = &{$child1->{'tostring'}} ($child1);
  $this->{'text'} = "${text0}[$text1]";
}
sub new_arrayaccess {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            tocode => *arrayaccess_tocode,
            tostring => *arrayaccess_tostring,
            type => $NT_ARRAYACCESS);
}
sub parse_arrayaccess {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  ($node, $s) = parse_primitive ($s, $s0, $parent);
  while ($s =~ /^\s*(\[)/) {
    $s = $';
    my $child0 = $node;
    my $child1 = '';
    ($child1, $s) = parse_assignment ($s, $s0, $parent);
    $s =~ /^\s*(\])/ or parse_error ("] expected", $s, $s0);
    $s =~ $';
    $node = new_arrayaccess ($child0, $child1);
    $node->{'parent'} = $parent;
  }
  ($node, $s);
}

my @TEXT_PALET_OF_K = (
  '(tp >>> 28)',
  '(tp >>> 24 & 15)',
  '(tp >>> 20 & 15)',
  '(tp >>> 16 & 15)',
  '(tp >>> 12 & 15)',
  '(tp >>> 8 & 15)',
  '(tp >>> 4 & 15)',
  '(tp & 15)'
  );

#  関数呼び出し
sub function_evaluate {
  my ($this, $status) = @_;
  my $children = [map { &{$_->{'evaluate'}} ($_, $status) } @{$this->{'children'}}];
  my $name = $children->[0]->{'type'} == $NT_ID ? $children->[0]->{'text'} : '';
  $status->{"id_$name"} = 1;
  my $k = $status->{'k'};
  #if ($name eq 'cto') {
  #  @$children == 2 or die "wrong length of parameter list of $name"
  #  return new_arrayaccess (new_id ('VideoController.vcnPalTbl'),
  #                          $children->[1]);
  #}
  #if ($name eq 'mix') {
  #  @$children == 3 or die "wrong length of parameter list of $name"
  #  return new_function ('VideoController.vcnMix2',
  #                       $children->[1],
  #                       $children->[2]);
  #}
  if ($name eq 'spp') {
    @$children == 1 or die "wrong length of parameter list of $name";
    return new_arrayaccess (new_id ('SpriteScreen.sprBuffer'),
                            $k == 0 ?
                            new_id ('sx') :
                            new_addition (new_id ('sx'),
                                          new_int ($k)));
  }
  #if ($name eq 'spc' ||
  #    $name eq 'tpc') {
  #  @$children == 2 or die "wrong length of parameter list of $name";
  #  return new_arrayaccess (new_id ('VideoController.vcnPal16TS'),
  #                          $children->[1]);
  #}
  #if ($name eq 'spo' ||
  #    $name eq 'tpo') {
  #  @$children == 2 or die "wrong length of parameter list of $name";
  #  return new_arrayaccess (new_id ('VideoController.vcnPal32TS'),
  #                          $children->[1]);
  #}
  if ($name eq 'txp') {
    @$children == 1 or die "wrong length of parameter list of $name";
    return ($k == 0 ?
            new_unsignedshiftright (new_id ('tp'),
                                    new_int (28)) :
            $k < 7 ?
            new_bitwiseand (new_unsignedshiftright (new_id ('tp'),
                                                    new_int (28 - 4 * $k)),
                            new_int (15)) :
            new_bitwiseand (new_id ('tp'),
                            new_int (15)));
  }
  if ($name eq 'e1p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    return new_arrayaccess (new_id ('GraphicScreen.graM4'),
                            new_bitwiseior (new_id ('gy1st'),
                                            new_bitwiseand ($k == 0 ?
                                                            new_id ('gx1st') :
                                                            new_addition (new_id ('gx1st'),
                                                                          new_int ($k)),
                                                            new_int (511))));
  }
  if ($name eq 'e2p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    return new_arrayaccess (new_id ('GraphicScreen.graM4'),
                            new_bitwiseior (new_id ('gy2nd'),
                                            new_bitwiseand ($k == 0 ?
                                                            new_id ('gx2nd') :
                                                            new_addition (new_id ('gx2nd'),
                                                                          new_int ($k)),
                                                            new_int (511))));
  }
  if ($name eq 'e2q') {
    @$children == 1 or die "wrong length of parameter list of $name";
    return new_arrayaccess (new_id ('GraphicScreen.graM4'),
                            new_bitwiseior (new_id ('gz2nd'),
                                            new_bitwiseand ($k == 0 ?
                                                            new_id ('gx2nd') :
                                                            new_addition (new_id ('gx2nd'),
                                                                          new_int ($k)),
                                                            new_int (511))));
  }
  if ($name eq 'e3p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    return new_arrayaccess (new_id ('GraphicScreen.graM4'),
                            new_bitwiseior (new_id ('gy3rd'),
                                            new_bitwiseand ($k == 0 ?
                                                            new_id ('gx3rd') :
                                                            new_addition (new_id ('gx3rd'),
                                                                          new_int ($k)),
                                                            new_int (511))));
  }
  if ($name eq 'e4p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    return new_arrayaccess (new_id ('GraphicScreen.graM4'),
                            new_bitwiseior (new_id ('gy4th'),
                                            new_bitwiseand ($k == 0 ?
                                                            new_id ('gx4th') :
                                                            new_addition (new_id ('gx4th'),
                                                                          new_int ($k)),
                                                            new_int (511))));
  }
  #if ($name eq 'epc' ||
  #    $name eq 'fpc' ||
  #    $name eq 'hpc' ||
  #    $name eq 'ipc') {
  #  @$children == 2 or die "wrong length of parameter list of $name";
  #  return new_arrayaccess (new_id ('VideoController.vcnPal16G8'),
  #                          $children->[1]);
  #}
  #if ($name eq 'epo' ||
  #    $name eq 'fpo' ||
  #    $name eq 'hpo' ||
  #    $name eq 'ipo') {
  #  @$children == 2 or die "wrong length of parameter list of $name";
  #  return new_arrayaccess (new_id ('VideoController.vcnPal32G8'),
  #                          $children->[1]);
  #}
if(0){
  if ($name eq 'f1p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    return new_bitwiseior (new_shiftleft (new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                                           new_bitwiseior (new_id ('gy2nd'),
                                                                           new_bitwiseand ($k == 0 ?
                                                                                           new_id ('gx2nd') :
                                                                                           new_addition (new_id ('gx2nd'),
                                                                                                         new_id ($k)),
                                                                                           new_int (511)))),
                                          new_int (4)),
                           new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                            new_bitwiseior (new_id ('gy1st'),
                                                            new_bitwiseand ($k == 0 ?
                                                                            new_id ('gx1st') :
                                                                            new_addition (new_id ('gx1st'),
                                                                                          new_id ($k)),
                                                                            new_int (511)))));
  }
  if ($name eq 'f2p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    return new_bitwiseior (new_shiftleft (new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                                           new_bitwiseior (new_id ('gy4th'),
                                                                           new_bitwiseand ($k == 0 ?
                                                                                           new_id ('gx4th') :
                                                                                           new_addition (new_id ('gx4th'),
                                                                                                         new_id ($k)),
                                                                                           new_int (511)))),
                                          new_int (4)),
                           new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                            new_bitwiseior (new_id ('gy3rd'),
                                                            new_bitwiseand ($k == 0 ?
                                                                            new_id ('gx3rd') :
                                                                            new_addition (new_id ('gx3rd'),
                                                                                          new_id ($k)),
                                                                            new_int (511)))));
  }
  if ($name eq 'f2q') {
    @$children == 1 or die "wrong length of parameter list of $name";
    return new_bitwiseior (new_shiftleft (new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                                           new_bitwiseior (new_id ('gz4th'),
                                                                           new_bitwiseand ($k == 0 ?
                                                                                           new_id ('gx4th') :
                                                                                           new_addition (new_id ('gx4th'),
                                                                                                         new_id ($k)),
                                                                                           new_int (511)))),
                                          new_int (4)),
                           new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                            new_bitwiseior (new_id ('gz3rd'),
                                                            new_bitwiseand ($k == 0 ?
                                                                            new_id ('gx3rd') :
                                                                            new_addition (new_id ('gx3rd'),
                                                                                          new_id ($k)),
                                                                            new_int (511)))));
  }
  if ($name eq 'g1p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    return new_bitwiseior (new_bitwiseior (new_bitwiseior (new_shiftleft (new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                                                                           new_bitwiseior (new_id ('gy4th'),
                                                                                                           new_bitwiseand ($k == 0 ?
                                                                                                                           new_id ('gx4th') :
                                                                                                                           new_addition (new_id ('gx4th'),
                                                                                                                                         new_id ($k)),
                                                                                                                           new_int (511)))),
                                                                          new_int (12)),
                                                           new_shiftleft (new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                                                                           new_bitwiseior (new_id ('gy3rd'),
                                                                                                           new_bitwiseand ($k == 0 ?
                                                                                                                           new_id ('gx3rd') :
                                                                                                                           new_addition (new_id ('gx3rd'),
                                                                                                                                         new_id ($k)),
                                                                                                                           new_int (511)))),
                                                                          new_int (8))),
                                           new_shiftleft (new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                                                           new_bitwiseior (new_id ('gy2nd'),
                                                                                           new_bitwiseand ($k == 0 ?
                                                                                                           new_id ('gx2nd') :
                                                                                                           new_addition (new_id ('gx2nd'),
                                                                                                                         new_id ($k)),
                                                                                                           new_int (511)))),
                                                          new_int (4))),
                           new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                            new_bitwiseior (new_id ('gy1st'),
                                                            new_bitwiseand ($k == 0 ?
                                                                            new_id ('gx1st') :
                                                                            new_addition (new_id ('gx1st'),
                                                                                          new_id ($k)),
                                                                            new_int (511)))));
  }
}
  #if ($name eq 'gpc' ||
  #    $name eq 'jpc') {
  #  @$children == 3 or die "wrong length of parameter list of $name";
  #  return new_bitwiseior (new_arrayaccess (new_id ('VideoController.vcnPal8G16H'),
  #                                          new_shiftright ($children->[1],
  #                                                          new_int (8))),
  #                         new_arrayaccess (new_id ('VideoController.vcnPal8G16L'),
  #                                          new_bitwiseand ($children->[2],
  #                                                          new_int (255))));
  #}
  #if ($name eq 'gpo' ||
  #    $name eq 'jpo') {
  #  @$children == 3 or die "wrong length of parameter list of $name";
  #  return new_arrayaccess (new_id ('VideoController.vcnPalTbl'),
  #                          new_bitwiseior (new_arrayaccess (new_id ('VideoController.vcnPal8G16H'),
  #                                                           new_shiftright ($children->[1],
  #                                                                           new_int (8))),
  #                                          new_arrayaccess (new_id ('VideoController.vcnPal8G16L'),
  #                                                           new_bitwiseand ($children->[2],
  #                                                                           new_int (255)))));
  #}
  if ($name eq 'h1p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    return new_arrayaccess (new_id ('GraphicScreen.graM4'),
                            $k == 0 ?
                            new_id ('ga') :
                            new_addition (new_id ('ga'),
                                          new_int ($k)));
  }
if(0){
  if ($name eq 'i1p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    return new_bitwiseior (new_shiftleft (new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                                           new_addition (new_id ('ga'),
                                                                         new_int (0x100000 + $k))),
                                          new_int (4)),
                           new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                            $k == 0 ?
                                            new_id ('ga') :
                                            new_addition (new_id ('ga'),
                                                          new_int ($k))));
  }
  if ($name eq 'j1p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    return new_bitwiseior (new_bitwiseior (new_bitwiseior (new_shiftleft (new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                                                                           new_addition (new_id ('ga'),
                                                                                                         new_int (0x300000 + $k))),
                                                                          new_int (12)),
                                                           new_shiftleft (new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                                                                           new_addition (new_id ('ga'),
                                                                                                         new_int (0x200000 + $k))),
                                                                          new_int (8))),
                                           new_shiftleft (new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                                                           new_addition (new_id ('ga'),
                                                                                         new_int (0x100000 + $k))),
                                                          new_int (4))),
                           new_arrayaccess (new_id ('GraphicScreen.graM4'),
                                            $k == 0 ?
                                            new_id ('ga') :
                                            new_addition (new_id ('ga'),
                                                          new_int ($k))));
  }
}
  new_node (children => $children,
            evaluate => $this->{'evaluate'},
            number => $this->{'number'},
            operator => $this->{'operator'},
            #parent => '',
            #text => '',
            tocode => $this->{'tocode'},
            tostring => $this->{'tostring'},
            type => $this->{'type'},
            varmap => $this->{'varmap'});
}
sub function_tocode {
  my ($this, $status) = @_;
  my $children = $this->{'children'};
  my $name = $children->[0]->{'text'};
  $status->{"id_$name"} = 1;
  my $k = $status->{'k'};
  my $pk = $k == 0 ? '' : ' + ' . $k;
  my $pka1 = ' + ' . (0x100000 + $k);
  my $pka2 = ' + ' . (0x200000 + $k);
  my $pka3 = ' + ' . (0x300000 + $k);
  if ($name eq 'cto') {
    @$children == 2 or die "wrong length of parameter list of $name";
    my $p = $children->[1];
    if ($p->{'type'} == $NT_INT ||
      $p->{'type'} == $NT_ID) {  #整数または識別子のときは改行しない
      put_text ('VideoController.vcnPalTbl[', $status);
      &{$p->{'tocode'}} ($p, $status);
      put_text (']', $status);
    } else {
      put_newline ("VideoController.vcnPalTbl[\n", $status);
      $status->{'indent'} += 2;
      &{$p->{'tocode'}} ($p, $status);
      $status->{'indent'} -= 2;
      put_text (']', $status);
    }
  } elsif ($name eq 'mix') {
    @$children == 3 or die "wrong length of parameter list of $name";
    my $p = $children->[1];
    my $q = $children->[2];
    if (($p->{'type'} == $NT_INT ||
      $p->{'type'} == $NT_ID) &&
        ($q->{'type'} == $NT_INT ||
          $q->{'type'} == $NT_ID)) {  #両方整数または識別子のときは改行しない
      put_text ('VideoController.vcnMix2 (', $status);
      &{$p->{'tocode'}} ($p, $status);
      put_text (', ', $status);
      &{$p->{'tocode'}} ($q, $status);
      put_text (')', $status);
    } else {
      put_newline ("VideoController.vcnMix2 (\n", $status);
      $status->{'indent'} += 2;
      &{$p->{'tocode'}} ($p, $status);
      put_newline (",\n", $status);
      &{$q->{'tocode'}} ($q, $status);
      $status->{'indent'} -= 2;
      put_text (')', $status);
    }
  } elsif ($name eq 'spp') {
    @$children == 1 or die "wrong length of parameter list of $name";
    put_text ("SpriteScreen.sprBuffer[sx$pk]", $status);
  } elsif ($name eq 'spc' ||
           $name eq 'tpc') {
    @$children == 2 or die "wrong length of parameter list of $name";
    my $p = $children->[1];
    put_left ('VideoController.vcnPal16TS[', $status);
    &{$p->{'tocode'}} ($p, $status);
    put_right (']', $status);
  } elsif ($name eq 'spo' ||
           $name eq 'tpo') {
    @$children == 2 or die "wrong length of parameter list of $name";
    my $p = $children->[1];
    put_left ('VideoController.vcnPal32TS[', $status);
    &{$p->{'tocode'}} ($p, $status);
    put_right (']', $status);
  } elsif ($name eq 'txp') {
    @$children == 1 or die "wrong length of parameter list of $name";
    put_text ($TEXT_PALET_OF_K[$k], $status);
  } elsif ($name eq 'e1p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    put_text ("GraphicScreen.graM4[gy1st | gx1st$pk & 511]", $status);
  } elsif ($name eq 'e2p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    put_text ("GraphicScreen.graM4[gy2nd | gx2nd$pk & 511]", $status);
  } elsif ($name eq 'e2q') {
    @$children == 1 or die "wrong length of parameter list of $name";
    put_text ("GraphicScreen.graM4[gz2nd | gx2nd$pk & 511]", $status);
  } elsif ($name eq 'e3p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    put_text ("GraphicScreen.graM4[gy3rd | gx3rd$pk & 511]", $status);
  } elsif ($name eq 'e4p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    put_text ("GraphicScreen.graM4[gy4th | gx4th$pk & 511]", $status);
  } elsif ($name eq 'epc' ||
           $name eq 'fpc' ||
           $name eq 'hpc' ||
           $name eq 'ipc') {
    @$children == 2 or die "wrong length of parameter list of $name";
    my $p = $children->[1];
    put_left ('VideoController.vcnPal16G8[', $status);
    &{$p->{'tocode'}} ($p, $status);
    put_right (']', $status);
  } elsif ($name eq 'epo' ||
           $name eq 'fpo' ||
           $name eq 'hpo' ||
           $name eq 'ipo') {
    @$children == 2 or die "wrong length of parameter list of $name";
    my $p = $children->[1];
    put_left ('VideoController.vcnPal32G8[', $status);
    &{$p->{'tocode'}} ($p, $status);
    put_right (']', $status);
  } elsif ($name eq 'f1p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    put_left ('(', $status);
    put_newline ("GraphicScreen.graM4[gy2nd | gx2nd$pk & 511] << 4 |\n", $status);
    put_right ("GraphicScreen.graM4[gy1st | gx1st$pk & 511])", $status);
  } elsif ($name eq 'f2p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    put_left ('(', $status);
    put_newline ("GraphicScreen.graM4[gy4th | gx4th$pk & 511] << 4 |\n", $status);
    put_right ("GraphicScreen.graM4[gy3rd | gx3rd$pk & 511])", $status);
  } elsif ($name eq 'f2q') {
    @$children == 1 or die "wrong length of parameter list of $name";
    put_left ('(', $status);
    put_newline ("GraphicScreen.graM4[gz4th | gx4th$pk & 511] << 4 |\n", $status);
    put_right ("GraphicScreen.graM4[gz3rd | gx3rd$pk & 511])", $status);
  } elsif ($name eq 'g1p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    put_left ('(', $status);
    put_newline ("GraphicScreen.graM4[gy4th | gx4th$pk & 511] << 12 |\n", $status);
    put_newline ("GraphicScreen.graM4[gy3rd | gx3rd$pk & 511] << 8 |\n", $status);
    put_newline ("GraphicScreen.graM4[gy2nd | gx2nd$pk & 511] << 4 |\n", $status);
    put_right ("GraphicScreen.graM4[gy1st | gx1st$pk & 511])", $status);
  } elsif ($name eq 'gpc' ||
           $name eq 'jpc') {
    @$children == 3 or die "wrong length of parameter list of $name";
    my $p = $children->[1];
    my $q = $children->[2];
    put_left ('(', $status);
    put_left ('VideoController.vcnPal8G16H[', $status);
    $NT_SHIFT < $p->{'type'} and put_left ('(', $status);
    &{$p->{'tocode'}} ($p, $status);
    $NT_SHIFT < $p->{'type'} and put_right (')', $status);
    put_right (' >> 8]', $status);
    put_newline (" |\n", $status);
    put_left ('VideoController.vcnPal8G16L[', $status);
    $NT_BITWISEAND < $q->{'type'} and put_left ('(', $status);
    &{$q->{'tocode'}} ($q, $status);
    $NT_BITWISEAND < $q->{'type'} and put_right (')', $status);
    put_right (' & 255]', $status);
    put_right (')', $status);
  } elsif ($name eq 'gpo' ||
           $name eq 'jpo') {
    @$children == 3 or die "wrong length of parameter list of $name";
    my $p = $children->[1];
    my $q = $children->[2];
    put_newline ("VideoController.vcnPalTbl[\n", $status);
    $status->{'indent'} += 2;
    put_left ('VideoController.vcnPal8G16H[', $status);
    $NT_SHIFT < $p->{'type'} and put_left ('(', $status);
    &{$p->{'tocode'}} ($p, $status);
    $NT_SHIFT < $p->{'type'} and put_right (')', $status);
    put_right (' >> 8]', $status);
    put_newline (" |\n", $status);
    put_left ('VideoController.vcnPal8G16L[', $status);
    $NT_BITWISEAND < $q->{'type'} and put_left ('(', $status);
    &{$q->{'tocode'}} ($q, $status);
    $NT_BITWISEAND < $q->{'type'} and put_right (')', $status);
    put_right (' & 255]', $status);
    $status->{'indent'} -= 2;
    put_text (']', $status);
  } elsif ($name eq 'h1p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    put_text ("GraphicScreen.graM4[ga$pk]", $status);
  } elsif ($name eq 'i1p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    put_left ('(', $status);
    put_newline ("GraphicScreen.graM4[ga$pka1] << 4 |\n", $status);
    put_right ("GraphicScreen.graM4[ga$pk])", $status);
  } elsif ($name eq 'j1p') {
    @$children == 1 or die "wrong length of parameter list of $name";
    put_left ('(', $status);
    put_newline ("GraphicScreen.graM4[ga$pka3] << 12 |\n", $status);
    put_newline ("GraphicScreen.graM4[ga$pka2] << 8 |\n", $status);
    put_newline ("GraphicScreen.graM4[ga$pka1] << 4 |\n", $status);
    put_right ("GraphicScreen.graM4[ga$pk])", $status);
  } else {
    die $name;
  }
}
sub function_tostring {
  my ($this) = @_;
  my ($child0, @children) = @{$this->{'children'}};
  $this->{'text'} = &{$child0->{'tostring'}} ($child0) . '(' . join (',', map { &{$_->{'tostring'}} ($_) } @children) . ')';
}
sub new_function {
  my ($name, @params) = @_;
  new_node (children => [new_id ($name), @params],
            evaluate => *function_evaluate,
            tocode => *function_tocode,
            tostring => *function_tostring,
            type => $NT_FUNCTION);
}
sub parse_function {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  ($node, $s) = parse_arrayaccess ($s, $s0, $parent);
  if ($s =~ /^\s*(\()/) {
    $s = $';
    $node->{'type'} == $NT_ID or parse_error ("function name expected", $s, $s0);
    my $name = $node->{'text'};
    my @params;
    if ($s =~ /^\s*(\))/) {
      $s = $';
    } else {
      for (;;) {
        my $child = '';
        ($child, $s) = parse_assignment ($s, $s0, $parent);
        push @params, $child;
        if ($s =~ /^\s*(,)/) {
          $s = $';
        } elsif ($s =~ /^\s*(\))/) {
          $s = $';
          last;
        } else {
          parse_error (", or ) expected", $s, $s0);
        }
      }
    }
    $node = new_function ($name, @params);
    $node->{'parent'} = $parent;
  }
  ($node, $s);
}

#  単項
sub unary_tocode {
  my ($this, $status) = @_;
  my $x = $this->{'children'}->[0];
  put_text ($this->{'operator'}, $status);
  $this->{'type'} <= $x->{'type'} and put_left ('(', $status);  #-(-x)の括弧は必要
  &{$x->{'tocode'}} ($x, $status);
  $this->{'type'} <= $x->{'type'} and put_right (')', $status);
}
sub unary_tostring {
  my ($this) = @_;
  my ($child0) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  $child0->{'type'} >= $this->{'type'} and $text0 = "($text0)";
  $this->{'text'} = "$this->{'operator'}$text0";
}
sub new_logicalnot {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '!',
            tocode => *unary_tocode,
            tostring => *unary_tostring,
            type => $NT_UNARY);
}
sub new_plussign {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '+',
            tocode => *unary_tocode,
            tostring => *unary_tostring,
            type => $NT_UNARY);
}
sub new_minussign {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '-',
            tocode => *unary_tocode,
            tostring => *unary_tostring,
            type => $NT_UNARY);
}
sub new_bitwisenot {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '~',
            tocode => *unary_tocode,
            tostring => *unary_tostring,
            type => $NT_UNARY);
}
sub parse_unary {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  if ($s =~ /^\s*(!(?!=)|\+(?![+=])|-(?![-=])|~(?!=))/) {
    my $operator = $1;
    $s = $';
    ($node, $s) = parse_unary ($s, $s0, $parent);
    if ($operator eq '!') {
      $node = new_logicalnot ($node);
    } elsif ($operator eq '+') {
      $node = new_plussign ($node);
    } elsif ($operator eq '-') {
      $node = new_minussign ($node);
    } elsif ($operator eq '~') {
      $node = new_bitwisenot ($node);
    } else {
      die;
    }
    $node->{'parent'} = $parent;
  } else {
    ($node, $s) = parse_function ($s, $s0, $parent);
  }
  ($node, $s);
}

#  左結合の二項演算子
sub binary_operator_tocode {
  my ($this, $status) = @_;
  my $x = $this->{'children'}->[0];
  my $y = $this->{'children'}->[1];
  $this->{'type'} < $x->{'type'} and put_left ('(', $status);  #(a*b)*cの括弧は不要
  &{$x->{'tocode'}} ($x, $status);
  $this->{'type'} < $x->{'type'} and put_right (')', $status);
  put_text (" $this->{'operator'} ", $status);
  $this->{'type'} <= $y->{'type'} and put_left ('(', $status);  #a*(b*c)の括弧は必要
  &{$y->{'tocode'}} ($y, $status);
  $this->{'type'} <= $y->{'type'} and put_right (')', $status);
}

#  乗除算
sub multiplication_tostring {
  my ($this) = @_;
  my ($child0, $child1) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  $child0->{'type'} > $this->{'type'} and $text0 = "($text0)";
  my $text1 = &{$child1->{'tostring'}} ($child1);
  $child1->{'type'} >= $this->{'type'} and $text1 = "($text1)";
  $this->{'text'} = "$text0$this->{'operator'}$text1";
}
sub new_multiplication {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '*',
            tocode => *binary_operator_tocode,
            tostring => *multiplication_tostring,
            type => $NT_MULTIPLICATION);
}
sub new_division {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '/',
            tocode => *binary_operator_tocode,
            tostring => *multiplication_tostring,
            type => $NT_MULTIPLICATION);
}
sub new_reminder {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '%',
            tocode => *binary_operator_tocode,
            tostring => *multiplication_tostring,
            type => $NT_MULTIPLICATION);
}
sub parse_multiplication {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  ($node, $s) = parse_unary ($s, $s0, $parent);
  while ($s =~ /^\s*(\*(?!=)|\/(?!=)|%(?!=))/) {
    my $operator = $1;
    $s = $';
    my $child0 = $node;
    my $child1 = '';
    ($child1, $s) = parse_unary ($s, $s0, $parent);
    if ($operator eq '*') {
      $node = new_multiplication ($child0, $child1);
    } elsif ($operator eq '/') {
      $node = new_division ($child0, $child1);
    } elsif ($operator eq '%') {
      $node = new_reminder ($child0, $child1);
    } else {
      die;
    }
    $node->{'parent'} = $parent;
  }
  ($node, $s);
}

#  加減算
sub addition_tostring {
  my ($this) = @_;
  my ($child0, $child1) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  $child0->{'type'} > $this->{'type'} and $text0 = "($text0)";
  my $text1 = &{$child1->{'tostring'}} ($child1);
  $child1->{'type'} >= $this->{'type'} and $text1 = "($text1)";
  $this->{'text'} = "$text0$this->{'operator'}$text1";
}
sub new_addition {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '+',
            tocode => *binary_operator_tocode,
            tostring => *addition_tostring,
            type => $NT_ADDITION);
}
sub new_subtraction {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '-',
            tocode => *binary_operator_tocode,
            tostring => *addition_tostring,
            type => $NT_ADDITION);
}
sub parse_addition {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  ($node, $s) = parse_multiplication ($s, $s0, $parent);
  while ($s =~ /^\s*(\+(?![+=])|-(?![-=]))/) {
    my $operator = $1;
    $s = $';
    my $child0 = $node;
    my $child1 = '';
    ($child1, $s) = parse_multiplication ($s, $s0, $parent);
    if ($operator eq '+') {
      $node = new_addition ($child0, $child1);
    } elsif ($operator eq '-') {
      $node = new_subtraction ($child0, $child1);
    } else {
      die;
    }
    $node->{'parent'} = $parent;
  }
  ($node, $s);
}

#  シフト
sub shift_tostring {
  my ($this) = @_;
  my ($child0, $child1) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  $child0->{'type'} > $this->{'type'} and $text0 = "($text0)";
  my $text1 = &{$child1->{'tostring'}} ($child1);
  $child1->{'type'} >= $this->{'type'} and $text1 = "($text1)";
  $this->{'text'} = "$text0$this->{'operator'}$text1";
}
sub new_shiftleft {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '<<',
            tocode => *binary_operator_tocode,
            tostring => *shift_tostring,
            type => $NT_SHIFT);
}
sub new_shiftright {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '>>',
            tocode => *binary_operator_tocode,
            tostring => *shift_tostring,
            type => $NT_SHIFT);
}
sub new_unsignedshiftright {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '>>>',
            tocode => *binary_operator_tocode,
            tostring => *shift_tostring,
            type => $NT_SHIFT);
}
sub parse_shift {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  ($node, $s) = parse_addition ($s, $s0, $parent);
  while ($s =~ /^\s*(<<(?!=)|>>(?![>=])|>>>(?!=))/) {
    my $operator = $1;
    $s = $';
    my $child0 = $node;
    my $child1 = '';
    ($child1, $s) = parse_addition ($s, $s0, $parent);
    if ($operator eq '<<') {
      $node = new_shiftleft ($child0, $child1);
    } elsif ($operator eq '>>') {
      $node = new_shiftright ($child0, $child1);
    } elsif ($operator eq '>>>') {
      $node = new_unsignedshiftright ($child0, $child1);
    } else {
      die;
    }
    $node->{'parent'} = $parent;
  }
  ($node, $s);
}

#  比較
sub comparison_tostring {
  my ($this) = @_;
  my ($child0, $child1) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  $child0->{'type'} > $this->{'type'} and $text0 = "($text0)";
  my $text1 = &{$child1->{'tostring'}} ($child1);
  $child1->{'type'} >= $this->{'type'} and $text1 = "($text1)";
  $this->{'text'} = "$text0$this->{'operator'}$text1";
}
sub new_lessthan {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '<',
            tocode => *binary_operator_tocode,
            tostring => *comparison_tostring,
            type => $NT_COMPARISON);
}
sub new_lessthanorequal {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '<=',
            tocode => *binary_operator_tocode,
            tostring => *comparison_tostring,
            type => $NT_COMPARISON);
}
sub new_greaterthan {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '>',
            tocode => *binary_operator_tocode,
            tostring => *comparison_tostring,
            type => $NT_COMPARISON);
}
sub new_greaterthanorequal {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '>=',
            tocode => *binary_operator_tocode,
            tostring => *comparison_tostring,
            type => $NT_COMPARISON);
}
sub parse_comparison {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  ($node, $s) = parse_shift ($s, $s0, $parent);
  while ($s =~ /^\s*(<(?![<=])|<=|>(?![>=])|>=)/) {
    my $operator = $1;
    $s = $';
    my $child0 = $node;
    my $child1 = '';
    ($child1, $s) = parse_shift ($s, $s0, $parent);
    if ($operator eq '<') {
      $node = new_lessthan ($child0, $child1);
    } elsif ($operator eq '<=') {
      $node = new_lessthanorequal ($child0, $child1);
    } elsif ($operator eq '>') {
      $node = new_greaterthan ($child0, $child1);
    } elsif ($operator eq '>=') {
      $node = new_greaterthanorequal ($child0, $child1);
    } else {
      die;
    }
    $node->{'parent'} = $parent;
  }
  ($node, $s);
}

#  等価
sub equality_tostring {
  my ($this) = @_;
  my ($child0, $child1) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  $child0->{'type'} > $this->{'type'} and $text0 = "($text0)";
  my $text1 = &{$child1->{'tostring'}} ($child1);
  $child1->{'type'} >= $this->{'type'} and $text1 = "($text1)";
  $this->{'text'} = "$text0$this->{'operator'}$text1";
}
sub new_equal {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '==',
            tocode => *binary_operator_tocode,
            tostring => *equality_tostring,
            type => $NT_EQUALITY);
}
sub new_notequal {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '!=',
            tocode => *binary_operator_tocode,
            tostring => *equality_tostring,
            type => $NT_EQUALITY);
}
sub parse_equality {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  ($node, $s) = parse_comparison ($s, $s0, $parent);
  while ($s =~ /^\s*(==|!=)/) {
    my $operator = $1;
    $s = $';
    my $child0 = $node;
    my $child1 = '';
    ($child1, $s) = parse_comparison ($s, $s0, $parent);
    if ($operator eq '==') {
      $node = new_equal ($child0, $child1);
    } elsif ($operator eq '!=') {
      $node = new_notequal ($child0, $child1);
    } else {
      die;
    }
    $node->{'parent'} = $parent;
  }
  ($node, $s);
}

#  ビットAND
sub bitwiseand_tostring {
  my ($this) = @_;
  my ($child0, $child1) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  $child0->{'type'} > $this->{'type'} and $text0 = "($text0)";
  my $text1 = &{$child1->{'tostring'}} ($child1);
  $child1->{'type'} >= $this->{'type'} and $text1 = "($text1)";
  $this->{'text'} = "$text0$this->{'operator'}$text1";
}
sub new_bitwiseand {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '&',
            tocode => *binary_operator_tocode,
            tostring => *bitwiseand_tostring,
            type => $NT_BITWISEAND);
}
sub parse_bitwiseand {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  ($node, $s) = parse_equality ($s, $s0, $parent);
  while ($s =~ /^\s*(&(?![=&]))/) {
    my $operator = $1;
    $s = $';
    my $child0 = $node;
    my $child1 = '';
    ($child1, $s) = parse_equality ($s, $s0, $parent);
    $node = new_bitwiseand ($child0, $child1);
    $node->{'parent'} = $parent;
  }
  ($node, $s);
}

#  ビットEOR
sub bitwiseeor_tostring {
  my ($this) = @_;
  my ($child0, $child1) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  $child0->{'type'} > $this->{'type'} and $text0 = "($text0)";
  my $text1 = &{$child1->{'tostring'}} ($child1);
  $child1->{'type'} >= $this->{'type'} and $text1 = "($text1)";
  $this->{'text'} = "$text0$this->{'operator'}$text1";
}
sub new_bitwiseeor {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '^',
            tocode => *binary_operator_tocode,
            tostring => *bitwiseeor_tostring,
            type => $NT_BITWISEEOR);
}
sub parse_bitwiseeor {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  ($node, $s) = parse_bitwiseand ($s, $s0, $parent);
  while ($s =~ /^\s*(\^(?!=))/) {
    my $operator = $1;
    $s = $';
    my $child0 = $node;
    my $child1 = '';
    ($child1, $s) = parse_bitwiseand ($s, $s0, $parent);
    $node = new_bitwiseeor ($child0, $child1);
    $node->{'parent'} = $parent;
  }
  ($node, $s);
}

#  ビットIOR
sub bitwiseior_tostring {
  my ($this) = @_;
  my ($child0, $child1) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  $child0->{'type'} > $this->{'type'} and $text0 = "($text0)";
  my $text1 = &{$child1->{'tostring'}} ($child1);
  $child1->{'type'} >= $this->{'type'} and $text1 = "($text1)";
  $this->{'text'} = "$text0$this->{'operator'}$text1";
}
sub new_bitwiseior {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '|',
            tocode => *binary_operator_tocode,
            tostring => *bitwiseior_tostring,
            type => $NT_BITWISEIOR);
}
sub parse_bitwiseior {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  ($node, $s) = parse_bitwiseeor ($s, $s0, $parent);
  while ($s =~ /^\s*(\|(?![=\|]))/) {
    my $operator = $1;
    $s = $';
    my $child0 = $node;
    my $child1 = '';
    ($child1, $s) = parse_bitwiseeor ($s, $s0, $parent);
    $node = new_bitwiseior ($child0, $child1);
    $node->{'parent'} = $parent;
  }
  ($node, $s);
}

#  論理AND
sub logicaland_tostring {
  my ($this) = @_;
  my ($child0, $child1) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  $child0->{'type'} > $this->{'type'} and $text0 = "($text0)";
  my $text1 = &{$child1->{'tostring'}} ($child1);
  $child1->{'type'} >= $this->{'type'} and $text1 = "($text1)";
  $this->{'text'} = "$text0$this->{'operator'}$text1";
}
sub new_logicaland {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '&&',
            tocode => *binary_operator_tocode,
            tostring => *logicaland_tostring,
            type => $NT_LOGICALAND);
}
sub parse_logicaland {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  ($node, $s) = parse_bitwiseior ($s, $s0, $parent);
  while ($s =~ /^\s*(&&(?!=))/) {
    my $operator = $1;
    $s = $';
    my $child0 = $node;
    my $child1 = '';
    ($child1, $s) = parse_bitwiseior ($s, $s0, $parent);
    $node = new_logicaland ($child0, $child1);
    $node->{'parent'} = $parent;
  }
  ($node, $s);
}

#  論理IOR
sub logicalior_tostring {
  my ($this) = @_;
  my ($child0, $child1) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  $child0->{'type'} > $this->{'type'} and $text0 = "($text0)";
  my $text1 = &{$child1->{'tostring'}} ($child1);
  $child1->{'type'} >= $this->{'type'} and $text1 = "($text1)";
  $this->{'text'} = "$text0$this->{'operator'}$text1";
}
sub new_logicalior {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '||',
            tocode => *binary_operator_tocode,
            tostring => *logicalior_tostring,
            type => $NT_LOGICALIOR);
}
sub parse_logicalior {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  ($node, $s) = parse_logicaland ($s, $s0, $parent);
  while ($s =~ /^\s*(\|\|(?!=))/) {
    my $operator = $1;
    $s = $';
    my $child0 = $node;
    my $child1 = '';
    ($child1, $s) = parse_logicaland ($s, $s0, $parent);
    $node = new_logicalior ($child0, $child1);
    $node->{'parent'} = $parent;
  }
  ($node, $s);
}

#  条件
sub condition_tocode {
  my ($this, $status) = @_;
  my $x = $this->{'children'}->[0];
  my $y = $this->{'children'}->[1];
  my $z = $this->{'children'}->[2];
  $this->{'type'} <= $x->{'type'} and put_left ('(', $status);  #(a?b:c)?d:eの括弧は必要
  &{$x->{'tocode'}} ($x, $status);
  $this->{'type'} <= $x->{'type'} and put_right (')', $status);
  put_newline (" ?\n", $status);
  $this->{'type'} < $y->{'type'} and put_left ('(', $status);  #a?(b?c:d):eの括弧は不要
  &{$y->{'tocode'}} ($y, $status);
  $this->{'type'} < $y->{'type'} and put_right (')', $status);
  put_newline (" :\n", $status);
  $this->{'type'} < $z->{'type'} and put_left ('(', $status);  #a?b:(c?d:e)の括弧は不要
  &{$z->{'tocode'}} ($z, $status);
  $this->{'type'} < $z->{'type'} and put_right (')', $status);
}
sub condition_tostring {
  my ($this) = @_;
  my ($child0, $child1, $child2) = @{$this->{'children'}};
  my $text0 = &{$child0->{'tostring'}} ($child0);
  $child0->{'type'} > $this->{'type'} and $text0 = "($text0)";
  my $text1 = &{$child1->{'tostring'}} ($child1);
  $child1->{'type'} > $this->{'type'} and $text1 = "($text1)";
  my $text2 = &{$child2->{'tostring'}} ($child2);
  $child2->{'type'} > $this->{'type'} and $text2 = "($text2)";
  $this->{'text'} = "$text0?$text1:$text2";
}
sub new_condition {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            tocode => *condition_tocode,
            tostring => *condition_tostring,
            type => $NT_CONDITION);
}
sub parse_condition {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  ($node, $s) = parse_logicalior ($s, $s0, $parent);
  if ($s =~ /^\s*(\?)/) {
    $s = $';
    my $child0 = $node;
    my $child1 = '';
    ($child1, $s) = parse_condition ($s, $s0, $parent);
    $s =~ /^\s*(:)/ or parse_error (": expected", $s, $s0);
    $s = $';
    my $child2 = '';
    ($child2, $s) = parse_condition ($s, $s0, $parent);
    $node = new_condition ($child0, $child1, $child2);
    $node->{'parent'} = $parent;
  }
  ($node, $s);
}

#  代入
sub assignment_tocode {
  my ($this, $status) = @_;
  my $x = $this->{'children'}->[0];  #右辺
  my $y = $this->{'children'}->[1];  #左辺
  $this->{'type'} <= $y->{'type'} and put_left ('(', $status);  #(a=b)=cの括弧は必要
  &{$y->{'tocode'}} ($y, $status);
  $this->{'type'} <= $y->{'type'} and put_right (')', $status);
  put_text (" $this->{'operator'} ", $status);
  $this->{'type'} < $x->{'type'} and put_left ('(', $status);  #a=(b=c)の括弧は不要
  &{$x->{'tocode'}} ($x, $status);
  $this->{'type'} < $x->{'type'} and put_right (')', $status);
}
sub assignment_tostring {
  my ($this) = @_;
  my ($child0, $child1) = @{$this->{'children'}};  #(右辺,左辺)
  my $text0 = &{$child0->{'tostring'}} ($child0);  #右辺
  $child0->{'type'} >= $this->{'type'} and $text0 = "($text0)";
  my $text1 = &{$child1->{'tostring'}} ($child1);  #左辺
  $child1->{'type'} > $this->{'type'} and $text1 = "($text1)";
  $this->{'text'} = "$text1$this->{'operator'}$text0";  #左辺=右辺
}
sub new_assignment {
  my @params = @_;
  new_node (children => [@params],
            evaluate => *evaluate_operator,
            operator => '=',
            tocode => *assignment_tocode,
            tostring => *assignment_tostring,
            type => $NT_ASSIGNMENT);
}
sub parse_assignment {
  my ($s, $s0, $parent) = @_;
  my $node = '';
  ($node, $s) = parse_condition ($s, $s0, $parent);
  if ($s =~ /^\s*(=(?!=))/) {
    my $operator = $1;
    $s = $';
    $node->{'type'} == $NT_ID or parse_error ("variable name expected", $s, $s0);
    my $child0 = '';  #右辺
    my $child1 = $node;  #左辺
    ($child0, $s) = parse_assignment ($s, $s0, $parent);
    if ($operator eq '=') {
      $node = new_assignment ($child0, $child1);  #[右辺,左辺]。評価順
    } else {
      die;
    }
    $node->{'parent'} = $parent;
  }
  ($node, $s);
}

if (0) {
  foreach my $s ('f(1,2,3)',
                 '!1||+1||-1||~1',
                 '1*2||1/2||1%2',
                 '1+2||1-2',
                 '1<<2||1>>2||1>>>2',
                 '1<2||1<=2||1>2||1>=2',
                 '1==2||1!=2',
                 '1&2',
                 '1^2',
                 '1|2',
                 '1&&2',
                 '1||2',
                 '1?2:3',
                 'a=1') {
    print "======== $s ========\n";
    dump_node (pass2 ($s));
  }
}

if (0) {
  my $node = pass2 ('f(1,2,3)');
  print &{$node->{'tostring'}} ($node) . "\n";
  $node = pass2 ('f(4,5,6)');
  print &{$node->{'tostring'}} ($node) . "\n";
  $node = pass2 ('a=b=1');
  print &{$node->{'tostring'}} ($node) . "\n";
}



#================================================================================
#パス3
#  不揮発で時間のかかる関数呼び出しの結果をローカル変数に保存して2回目以降はローカル変数の参照で済ませる
#
#  関数呼び出しノード(参照ノード)を根に近い側を優先して走査する
#    参照ノードに通し番号を振る
#    参照ノードより前に確実に評価されるノードのリストを作る
#    参照ノードより前に確実に評価されるノードのリストの根に近い側から参照ノードと同じ構造の関数呼び出しノード(代入ノード)を探す
#    代入ノードがあるとき
#      参照ノードより前に評価される可能性のあるノードのリストを作る
#      参照ノードから代入ノードまでに評価される可能性のあるノードの変数使用状況マップに代入ノードの通し番号を記録する
#        (代入ノードは参照ノードよりも根に近い側にあるので参照ノードとして走査したときに通し番号が振られている)
#      参照ノードを通し番号を添えた変数名に置換する
#  変数名が割り当てられた代入ノードa(b,c)を代入演算子v=a(b,c)に置き換える
#
my $pass3_table;  #[$i]は$iと同時に使われている変数が記録されたバイナリベクタ
my @pass3_list;  #すべての変数の番号のリスト

sub pass3 {
  my ($tree) = @_;
  my $list = pass3_sub_1 ([], $tree);
  $pass3_table = [];
  @pass3_list = varr (pass3_sub_5 ($tree));  #すべての変数の番号のリスト
  foreach my $i (@pass3_list) {
    my $node = $list->[$i];  #代入ノード
    my $dummy = new_int (0);
    my $assignment = new_assignment ($dummy, new_id ("v$i"));  #右辺はダミー。replace_node($node,new_assignment($node,new_id("v$i")))だとnew_assignmentで$node->{'parent'}が書き換えられてしまいreplace_nodeできなくなるので、nodeをv=0に書き換えてから0をnodeに書き換える
    replace_node ($node, $assignment);  #node => v=0
    replace_node ($dummy, $node);  #0 => node
  }
}  #sub pass3

#  ツリーに含まれる関数呼び出しノードを評価順に処理する
#  根に近い関数呼び出しノードを処理したらその中に含まれる関数呼び出しノードは処理しない
sub pass3_sub_1 {
  my ($list, $rnode) = @_;
  if ($rnode->{'type'} == $NT_FUNCTION) {  #関数呼び出しノード(参照ノード)のとき
    my $rtext = $rnode->{'text'};
    my $llist = pass3_sub_2 ([], $rnode, 0);  #参照ノードより前に確実に評価されるノードのリスト
    foreach my $lnode (@$llist) {  #参照ノードより前に確実に評価されるノード(代入ノード)について根に近い方から順に
      if ($lnode->{'text'} eq $rtext) {  #代入ノードと参照ノードの構造が同じとき
        my $lnumber = $lnode->{'number'};  #代入ノードの番号
        my $mlist = pass3_sub_2 ([], $rnode, 1);  #参照ノードより前に評価される可能性があるノードのリスト
        while (@$mlist && $mlist->[0] ne $lnode) {
          shift @$mlist;  #代入ノードより前のノードを切り捨てる
        }
        @$mlist or die;
        foreach my $mnode (@$mlist) {
          defined $mnode->{'varmap'} or $mnode->{'varmap'} = vnew ();
          $mnode->{'varmap'} = vset ($mnode->{'varmap'}, $lnumber);  #参照ノードから代入ノードまでに評価される可能性のあるノードの変数使用状況マップに代入ノードの番号を記録する
        }
        replace_node ($rnode, new_id ("v$lnumber"));  #参照ノードを関数呼び出しから識別子に変更する
        return $list;
      }
    }
    $rnode->{'number'} = @$list;  #関数呼び出しノードに評価順に振った通し番号。参照ノードは含まない
    push @$list, $rnode;
  }
  foreach my $child (@{$rnode->{'children'}}) {
    pass3_sub_1 ($list, $child);
  }
  $list;
}  #sub pass3_sub_1

#ツリーの中のあるノードが評価されるときそこに至るまでに確実に評価されるノードのリストを作る
#  ボトムアップ
#    a(b,c)のcが評価されるとき、bは確実に評価されて結果は不明
#    a+bのbが評価されるとき、aは確実に評価されて結果は不明
#    a&&bのbが評価されるとき、aは確実に評価されて結果は真
#    a||bのbが評価されるとき、aは確実に評価されて結果は偽
#    a?b:cのbが評価されるとき、aは確実に評価されて結果は真
#    a?b:cのcが評価されるとき、aは確実に評価されて結果は偽
#    a=bのaが評価されるとき、bは確実に評価されて結果は不明
sub pass3_sub_2 {
  my ($list, $node, $all) = @_;
  my $sub_4_or_3 = $all ? *pass3_sub_4 : *pass3_sub_3;
  #unshift @$list, $node;
  my $child = $node;
  my $parent = $child->{'parent'};
  while ($parent) {
    unshift @$list, $parent;
    my $type = $parent->{'type'};
    my $children = $parent->{'children'};
    if ($type == $NT_FUNCTION) {
      my $i = $#$children;
      while (1 <= $i) {
        $child eq $children->[$i--] and last;
      }
      while (1 <= $i) {  #a(b,c)のcが評価されるとき
        &{$sub_4_or_3} ($list, $children->[$i--], 0);  #bは確実に評価されて結果は不明
      }
    } elsif ($type == $NT_ARRAYACCESS ||
             $type == $NT_MULTIPLICATION ||
             $type == $NT_ADDITION ||
             $type == $NT_SHIFT ||
             $type == $NT_COMPARISON ||
             $type == $NT_EQUALITY ||
             $type == $NT_BITWISEAND ||
             $type == $NT_BITWISEEOR ||
             $type == $NT_BITWISEIOR) {
      if ($child eq $children->[1]) {  #a+bのbが評価されるとき
        &{$sub_4_or_3} ($list, $children->[0], 0);  #aは確実に評価されて結果は不明
      }
    } elsif ($type == $NT_LOGICALAND) {
      if ($child eq $children->[1]) {  #a&&bのbが評価されるとき
        &{$sub_4_or_3} ($list, $children->[0], 1);  #aは確実に評価されて結果は真
      }
    } elsif ($type == $NT_LOGICALIOR) {
      if ($child eq $children->[1]) {  #a||bのbが評価されるとき
        &{$sub_4_or_3} ($list, $children->[0], 2);  #aは確実に評価されて結果は偽
      }
    } elsif ($type == $NT_CONDITION) {
      if ($child eq $children->[1]) {  #a?b:cのbが評価されるとき
        &{$sub_4_or_3} ($list, $children->[0], 1);  #aは確実に評価されて結果は真
      } elsif ($child eq $children->[2]) {  #a?b:cのcが評価されるとき
        &{$sub_4_or_3} ($list, $children->[0], 2);  #aは確実に評価されて結果は偽
      }
    } elsif ($type == $NT_ASSIGNMENT) {
      if ($child eq $children->[1]) {  #b=aのbが評価されるとき
        &{$sub_4_or_3} ($list, $children->[0], 0);  #aは確実に評価されて結果は不明
      }
    }
    $child = $parent;
    $parent = $parent->{'parent'};
  }
  $list;
}  #sub pass3_sub_2

#  トップダウン
#    a(b,c)が評価されて結果が不明または真または偽のとき、cは確実に評価されて結果は不明、bは確実に評価されて結果は不明
#    !aが評価されて結果が真のとき、aは確実に評価されて結果は偽
#    !aが評価されて結果が偽のとき、aは確実に評価されて結果は真
#    a+bが評価されて結果が不明または真または偽のとき、bは確実に評価されて結果は不明、aは確実に評価されて結果は不明
#    a&&bが評価されて結果が真のとき、bは確実に評価されて結果は真、aは確実に評価されて結果は真
#    a&&bが評価されて結果が不明または偽のとき、aは確実に評価されて結果は不明
#    a||bが評価されて結果が偽のとき、bは確実に評価されて結果は偽、aは確実に評価されて結果は偽
#    a||bが評価されて結果が不明または真のとき、aは確実に評価されて結果は不明
#    a?b:cが評価されて結果が不明または真または偽のとき、aは確実に評価されて結果は不明
#    b=aが評価されて結果が真のとき、aは確実に評価されて結果は真
#    b=aが評価されて結果が偽のとき、aは確実に評価されて結果は偽
sub pass3_sub_3 {
  my ($list, $node, $bool) = @_;
  unshift @$list, $node;
  my $type = $node->{'type'};
  my $children = $node->{'children'};
  if ($type == $NT_INT ||
      $type == $NT_ID) {
  } elsif ($type == $NT_FUNCTION) {  #a(b,c)が評価されて結果が不明または真または偽のとき
    for (my $i = $#$children; 1 <= $i; $i--) {
      pass3_sub_3 ($list, $children->[$i], 0);  #cは確実に評価されて結果は不明、bは確実に評価されて結果は不明
    }
  } elsif ($type == $NT_UNARY) {
    if ($node->{'operator'} eq '!' && $bool == 1) {  #!aが評価されて結果が真のとき
      pass3_sub_3 ($list, $children->[0], 2);  #aは確実に評価されて結果は偽
    } elsif ($node->{'operator'} eq '!' && $bool == 2) {  #!aが評価されて結果が偽のとき
      pass3_sub_3 ($list, $children->[0], 1);  #aは確実に評価されて結果は真
    } else {
      pass3_sub_3 ($list, $children->[0], 0);
    }
  } elsif ($type == $NT_ARRAYACCESS ||
           $type == $NT_MULTIPLICATION ||
           $type == $NT_ADDITION ||
           $type == $NT_SHIFT ||
           $type == $NT_COMPARISON ||
           $type == $NT_EQUALITY ||
           $type == $NT_BITWISEAND ||
           $type == $NT_BITWISEEOR ||
           $type == $NT_BITWISEIOR) {  #a+bが評価されて結果が不明または真または偽のとき
    pass3_sub_3 ($list, $children->[1], 0);  #bは確実に評価されて結果は不明
    pass3_sub_3 ($list, $children->[0], 0);  #aは確実に評価されて結果は不明
  } elsif ($type == $NT_LOGICALAND) {
    if ($bool == 1) {  #a&&bが評価されて結果が真のとき
      pass3_sub_3 ($list, $children->[1], 1);  #bは確実に評価されて結果は真
      pass3_sub_3 ($list, $children->[0], 1);  #aは確実に評価されて結果は真
    } else {  #a&&bが評価されて結果が不明または偽のとき
      pass3_sub_3 ($list, $children->[0], 0);  #aは確実に評価されて結果は不明
    }
  } elsif ($type == $NT_LOGICALIOR) {
    if ($bool == 2) {  #a||bが評価されて結果が偽のとき
      pass3_sub_3 ($list, $children->[1], 2);  #bは確実に評価されて結果は偽
      pass3_sub_3 ($list, $children->[0], 2);  #aは確実に評価されて結果は偽
    } else {  #a||bが評価されて結果が不明または真のとき
      pass3_sub_3 ($list, $children->[0], 0);  #aは確実に評価されて結果は不明
    }
  } elsif ($type == $NT_CONDITION) {  #a?b:cが評価されて結果が不明または真または偽のとき
    pass3_sub_3 ($list, $children->[0], 0);  #aは確実に評価されて結果は不明
  } elsif ($type == $NT_ASSIGNMENT) {
    if ($bool == 1) {  #b=aが評価されて結果が真のとき
      pass3_sub_3 ($list, $children->[0], 1);  #aは確実に評価されて結果は真
    } elsif ($bool == 2) {  #b=aが評価されて結果が偽のとき
      pass3_sub_3 ($list, $children->[0], 2);  #aは確実に評価されて結果は偽
    } else {
      pass3_sub_3 ($list, $children->[0], 0);
    }
    #pass3_sub_3 ($list, $children->[1], 0);
  } else {
    die;
  }
  $list;
}  #sub pass3_sub_3

#  トップダウン
#    評価される可能性があるすべてのノードのリストを作る
sub pass3_sub_4 {
  my ($list, $node) = @_;
  unshift @$list, $node;
  my $children = $node->{'children'};
  for (my $i = $#$children; 0 <= $i; $i--) {
    pass3_sub_4 ($list, $children->[$i]);
  }
  $list;
}  #sub pass3_sub_4

sub pass3_sub_5 {
  my ($node) = @_;
  my $all = vnew ();
  if (defined $node->{'varmap'}) {
    my $map = $node->{'varmap'};
    $all = vior ($all, $map);
    foreach my $i (varr ($map)) {
      $pass3_table->[$i] = vior ($pass3_table->[$i] // vnew (), $map);
    }
  }
  foreach my $child (@{$node->{'children'}}) {
    $all = vior ($all, pass3_sub_5 ($child));
  }
  $all;
}  #sub pass3_sub_5



#================================================================================
#パス4
#  変数の数を減らす
#    同時に使われていない変数を同じ変数に割り当て直すことで変数の数を減らす
#    1つのノードで同時に使われている最大の数まで減らせるとは限らない
#      3つのノードの変数使用状況マップが(v0,v1),(v0,v2),(v1,v2)のとき同時に使われている最大の数は2だが、
#      どの2つを選んでも同じ変数に割り当てられないので変数は3個必要
#    TE4S_XHCTは圧縮前の変数が74個ある。64bitでは足りない
#
#  $pass3_table->[$i]は$iと同時に使われている変数のマップ
#  vget($pass3_table->[$i],$j)が0ならば$iと$jは同時に使われていないので同じ変数に割り当てられる
#  $jを$iに融合したとき$pass3_table->[$i]=vior($pass3_table->[$i],$pass3_table->[$j])としてマップも融合する
#
my $pass4_conv;

sub pass4 {
  my ($tree) = @_;
  $pass4_conv = [];  #変数の番号の変換表
  if (0) {
    foreach my $i (@pass3_list) {
      print 'map ' . $i . ' ' . join (',', varr ($pass3_table->[$i])) . "\n";
    }
  }
  foreach my $i (@pass3_list) {
    $pass4_conv->[$i] = $i;  #無変換
  }
  for (my $ii = 0; $ii <= @pass3_list - 2; $ii++) {
    my $i = $pass3_list[$ii];
    $pass4_conv->[$i] == $i or next;  #変換済み
    for (my $jj = $ii + 1; $jj <= @pass3_list - 1; $jj++) {
      my $j = $pass3_list[$jj];
      $pass4_conv->[$j] == $j or next;  #変換済み
      if (vget ($pass3_table->[$i], $j) == 0) {  #$iと$jが重複しない
        if (0) {
          print "marge $j => $i\n";
        }
        $pass3_table->[$i] = vior ($pass3_table->[$i], $pass3_table->[$j]);  #$jを$iに融合する
        $pass4_conv->[$j] = $i;  #$jを$iに変換する
      }
    }
  }
  #  変数の番号を詰める
  my $after = vset (vnew (), grep { defined $_ } @$pass4_conv);  #変換後の番号のマップ
  my $j = 0;  #詰めた後の番号
  my @b = ();
  while (!vnul ($after)) {
    my $i = vflo ($after);  #詰める前の番号
    $b[$i] = $j++;  #詰めた後の番号
    if (0) {
      print "compress $i => $b[$i]\n";
    }
    $after = vclr ($after, $i);
  }
  if (0) {
    print "number of variables: $j\n";
  }
  foreach my $i (@pass3_list) {
    $pass4_conv->[$i] = $b[$pass4_conv->[$i]];
  }
  pass4_sub_1 ($tree);
}  #sub pass4

sub pass4_sub_1 {
  my ($node) = @_;
  if ($node->{'type'} == $NT_ID) {
    if ($node->{'text'} =~ /^v(\d+)/) {
      $node->{'text'} = chr 112 + $pass4_conv->[$1];  #'p','q','r'
    }
  }
  foreach my $child (@{$node->{'children'}}) {
    pass4_sub_1 ($child);
  }
}  #sub pass4_sub_1



#================================================================================
#パス5
#  単純な関数を演算子に置き換える
#
#  演算子で書ける式の値も変数に割り当てられるように関数の形にしてある
#  変数の割り当てが完了したので演算子に戻す
#
sub pass5 {
  my ($node) = @_;
  if ($node->{'type'} == $NT_FUNCTION) {
    if ($node->{'children'}->[0]->{'text'} eq 'ls1') {  #ls1(p) => p&1
      my $p = $node->{'children'}->[1];  #p
      $node = replace_node ($node, new_bitwiseand ($p, new_int (1)));
    } elsif ($node->{'children'}->[0]->{'text'} eq 'ls4') {  #ls4(p) => p&15
      my $p = $node->{'children'}->[1];  #p
      $node = replace_node ($node, new_bitwiseand ($p, new_int (15)));
    } elsif ($node->{'children'}->[0]->{'text'} eq 'tev') {  #tev(a) => p&-2
      my $p = $node->{'children'}->[1];  #p
      $node = replace_node ($node, new_bitwiseand ($p, new_int (-2)));
    } elsif ($node->{'children'}->[0]->{'text'} eq 'tod') {  #tod(a) => p|1
      my $p = $node->{'children'}->[1];  #p
      $node = replace_node ($node, new_bitwiseior ($p, new_int (1)));
    }
  }
  foreach my $child (@{$node->{'children'}}) {
    pass5 ($child);
  }
}  #sub pass5



#================================================================================
#パス6
#  全体をcto()で囲む
#    cto(a?b:c) => a?cto(b):cto(c)
#    cto(spc(p)) => spo(p)
#    cto(tpc(p)) => tpo(p)
#    cto(epc(p)) => epo(p)
#    cto(fpc(p)) => fpo(p)
#    cto(gpc(p,q)) => gpo(p,q)
#    cto(hpc(p)) => hpo(p)
#    cto(ipc(p)) => ipo(p)
#    cto(jpc(p,q)) => jpo(p,q)
#    a?cto(b):cto(c) => cto(a?b:c)
#
#  cto(c)はX68000のカラー(16bit)をホストのARGB(32bit)に変換する関数
#  spo(p)などはX68000のパレットをホストのARGB(32bit)に変換する関数
#  cto(spc(p))などよりもspo(p)などの方が速いので、全体をcto(c)で囲んでからcto(spc(p))などをspo(p)などに変換する
#  条件演算子をcto(c)で囲むときは条件演算子の全体ではなくthen節とelse節をそれぞれcto(c)で囲んでからthen節とelse節を再帰処理して、
#  then節とelse節のどちらもspo(p)などに変換されなかったときはthen節とelse節をcto(c)で囲むのをやめて条件演算子の全体をcto(c)で囲む
#
sub pass6 {
  my ($tree) = @_;
  #  全体をcto()で囲む
  $tree = new_function ('cto', $tree);
  #  再帰処理
  $tree = pass6_sub ($tree);
  $tree;
}  #sub pass6

sub pass6_sub {
  my ($node) = @_;
  #  cto(a?b:c) => a?cto(b):cto(c)
  if ($node->{'type'} == $NT_FUNCTION &&
    $node->{'children'}->[0]->{'text'} eq 'cto' &&
      $node->{'children'}->[1]->{'type'} == $NT_CONDITION) {  #cto(a?b:c) => a?cto(b):cto(c)
    my $old_cond = $node->{'children'}->[1];  #a?b:c
    $node = replace_node ($node, new_condition ($old_cond->{'children'}->[0],  #a
                                                new_function ('cto', $old_cond->{'children'}->[1]),  #cto(b)
                                                new_function ('cto', $old_cond->{'children'}->[2])));  #cto(c)
  }
  #  cto(spc(p)) => spo(p)
  #  cto(tpc(p)) => tpo(p)
  #  cto(epc(p)) => epo(p)
  #  cto(fpc(p)) => fpo(p)
  #  cto(gpc(p,q)) => gpo(p,q)
  #  cto(hpc(p)) => hpo(p)
  #  cto(ipc(p)) => ipo(p)
  #  cto(jpc(p,q)) => jpo(p,q)
  if ($node->{'type'} == $NT_FUNCTION &&
    $node->{'children'}->[0]->{'text'} eq 'cto' &&
      $node->{'children'}->[1]->{'type'} == $NT_FUNCTION &&
        $node->{'children'}->[1]->{'children'}->[0]->{'text'} =~ /^[stefghij]pc$/) {  #cto(?pc(p[,q])) => ?po(p[,q])
    my $child = $node->{'children'}->[1];  #?pc(p[,q])
    $node = replace_node ($node, $child);
    $node->{'children'}->[0]->{'text'} =~ s/c$/o/;
  }
  #  子を処理する
  for (my $i = 0; $i < @{$node->{'children'}}; $i++) {  #childrenの内容が変わることがあるのでforeachは避ける
    pass6_sub ($node->{'children'}->[$i]);
  }
  #  a?cto(b):cto(c) => cto(a?b:c)
  if ($node->{'type'} == $NT_CONDITION &&
    $node->{'children'}->[1]->{'type'} == $NT_FUNCTION &&
      $node->{'children'}->[1]->{'children'}->[0]->{'text'} eq 'cto' &&
        $node->{'children'}->[2]->{'type'} == $NT_FUNCTION &&
          $node->{'children'}->[2]->{'children'}->[0]->{'text'} eq 'cto') {  #a?cto(b):cto(c) => cto(a?b:c)
    my $dummy = new_int (0);
    my $new_func = new_function ('cto', $dummy);
    my $new_cond = new_condition ($node->{'children'}->[0],  #a
                                  $node->{'children'}->[1]->{'children'}->[1],  #b
                                  $node->{'children'}->[2]->{'children'}->[1]);  #c
    $node = replace_node ($node, $new_func);
    replace_node ($dummy, $new_cond);
  }
  $node;
}  #sub pass6_sub



#================================================================================
#ソースコード
#
#  共通
#    ARGB cto(c)
#      VideoController.vcnPalTbl[c]
#    カラー mix(p,q)
#      VideoController.vcnMix2 (
#        p,
#        q)
#    準備
#      (kが使われなかったとき)
#      int cd = (k=0のARGB);  //定数データ
#    ローカル変数宣言
#      (rがあるとき)
#      int p, q, r;
#      (rがなくてqがあるとき)
#      int p, q;
#      (qとrがなくてpがあるとき)
#      int p;
#    構造
#      (準備)
#      int da = dst << XEiJ.PNL_BM_OFFSET_BITS;  //ARGB出力インデックス
#      int db = da + XEiJ.pnlScreenWidth;  //ARGB出力インデックスの終了位置
#      if (rh) {
#        int half = XEiJ.pnlScreenWidth >> 4 << 3;
#        (準備half)
#        da += half;
#      }
#      while (da < db) {
#        (ローカル変数宣言)
#        (kが使われなかったとき)
#        XEiJ.pnlBM[da] = cd;
#        XEiJ.pnlBM[da + 1] = cd;
#        XEiJ.pnlBM[da + 2] = cd;
#        XEiJ.pnlBM[da + 3] = cd;
#        XEiJ.pnlBM[da + 4] = cd;
#        XEiJ.pnlBM[da + 5] = cd;
#        XEiJ.pnlBM[da + 6] = cd;
#        XEiJ.pnlBM[da + 7] = cd;
#        (kが使われたとき)
#        XEiJ.pnlBM[da] = (k=0のARGB);
#        XEiJ.pnlBM[da + 1] = (k=1のARGB);
#        XEiJ.pnlBM[da + 2] = (k=2のARGB);
#        XEiJ.pnlBM[da + 3] = (k=3のARGB);
#        XEiJ.pnlBM[da + 4] = (k=4のARGB);
#        XEiJ.pnlBM[da + 5] = (k=5のARGB);
#        XEiJ.pnlBM[da + 6] = (k=6のARGB);
#        XEiJ.pnlBM[da + 7] = (k=7のARGB);
#        (更新8)
#        da += 8;
#      }  //while da<db
#
#  S  スプライト
#    スプライト準備
#      SpriteScreen.sprStep3 ();
#      int sx = 16;  //スプライトx座標
#    スプライト準備half
#      sx += half;
#    スプライトパレット spp()
#      k=0  SpriteScreen.sprBuffer[sx]
#      k=1  SpriteScreen.sprBuffer[sx + 1]
#      k=2  SpriteScreen.sprBuffer[sx + 2]
#      k=3  SpriteScreen.sprBuffer[sx + 3]
#      k=4  SpriteScreen.sprBuffer[sx + 4]
#      k=5  SpriteScreen.sprBuffer[sx + 5]
#      k=6  SpriteScreen.sprBuffer[sx + 6]
#      k=7  SpriteScreen.sprBuffer[sx + 7]
#    スプライトカラー spc(p)
#      VideoController.vcnPal16TS[p]
#    スプライトARGB spo(p)
#      VideoController.vcnPal32TS[p]
#    スプライト更新1
#        sx++;
#    スプライト更新8
#        sx += 8;
#
#  T  テキスト
#    テキストパレット txp()
#      k=0  (tp >>> 28)
#      k=1  (tp >>> 24 & 15)
#      k=2  (tp >>> 20 & 15)
#      k=3  (tp >>> 16 & 15)
#      k=4  (tp >>> 12 & 15)
#      k=5  (tp >>> 8 & 15)
#      k=6  (tp >>> 4 & 15)
#      k=7  (tp & 15)
#    テキストカラー tpc(p)
#      VideoController.vcnPal16TS[p]
#    テキストARGB tpo(p)
#      VideoController.vcnPal32TS[p]
#    テキスト構造
#      (準備)
#      int ty = CRTC.crtR11TxYZero + src & 1023;  //ラスタ
#      int tc = (ty & CRTC.crtMask3) << 7 | CRTC.crtR10TxXCurr >> 3;  //テキスト桁位置
#      int ta0 = 0x00e00000 + ((ty & CRTC.crtMaskMinus4) << 7);  //ラスタブロックアドレス
#      int ta1 = 0x00020000 + ta0;
#      int ta2 = 0x00040000 + ta0;
#      int ta3 = 0x00060000 + ta0;
#      int ts = CRTC.crtR10TxXCurr & 7;  //テキスト桁境界からのずれ
#      int da = dst << XEiJ.PNL_BM_OFFSET_BITS;  //ARGB出力インデックス
#      int db = da + XEiJ.pnlScreenWidth;  //ARGB出力インデックスの終了位置
#      if (rh) {
#        int half = XEiJ.pnlScreenWidth >> 4 << 3;
#        (準備half)
#        tc = tc + (half >> 3) & CRTC.crtMask511;
#        da += half;
#      }
#      if (ts == 0) {  //テキスト桁境界に合っているとき
#        while (da < db) {
#          int tp = (VideoController.VCN_TXP3[MainMemory.mmrM8[ta3 + tc] & 255] |
#                    VideoController.VCN_TXP2[MainMemory.mmrM8[ta2 + tc] & 255] |
#                    VideoController.VCN_TXP1[MainMemory.mmrM8[ta1 + tc] & 255] |
#                    VideoController.VCN_TXP0[MainMemory.mmrM8[ta0 + tc] & 255]);
#          tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置
#          (ローカル変数宣言)
#          XEiJ.pnlBM[da] = (k=0のARGB);
#          XEiJ.pnlBM[da + 1] = (k=1のARGB);
#          XEiJ.pnlBM[da + 2] = (k=2のARGB);
#          XEiJ.pnlBM[da + 3] = (k=3のARGB);
#          XEiJ.pnlBM[da + 4] = (k=4のARGB);
#          XEiJ.pnlBM[da + 5] = (k=5のARGB);
#          XEiJ.pnlBM[da + 6] = (k=6のARGB);
#          XEiJ.pnlBM[da + 7] = (k=7のARGB);
#          (更新8)
#          da += 8;
#        }  //while da<db
#      } else {  //テキスト桁境界に合っていないとき
#        //                                                             ts=1のとき
#        int tt = ts + 8;                                             //tt=9
#        ts += 16;                                                    //ts=17
#        //                                                             ........ ........ ........ 01234567  m8[ta0+tc]
#        int p0 = MainMemory.mmrM8[ta0 + tc] << ts;                   //.......0 1234567_ ________ ________  p0=m8[ta0+tc]<<ts
#        int p1 = MainMemory.mmrM8[ta1 + tc] << ts;
#        int p2 = MainMemory.mmrM8[ta2 + tc] << ts;
#        int p3 = MainMemory.mmrM8[ta3 + tc] << ts;
#        tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置
#        while (da < db) {
#          //                                                           ........ ........ .1234567 ________  p0>>tt
#          //                                                           ........ ........ .1234567 89abcdef  p0>>tt|m8[ta0+tc]&255
#          p0 = (p0 >> tt | MainMemory.mmrM8[ta0 + tc] & 255) << ts;  //12345678 9abcdef_ ________ ________  p0=(p0>>tt|m8[ta0+tc]&255)<<ts
#          p1 = (p1 >> tt | MainMemory.mmrM8[ta1 + tc] & 255) << ts;  //~~~~~~~~
#          p2 = (p2 >> tt | MainMemory.mmrM8[ta2 + tc] & 255) << ts;  //ここを使う
#          p3 = (p3 >> tt | MainMemory.mmrM8[ta3 + tc] & 255) << ts;
#          int tp = (VideoController.VCN_TXP3[p3 >>> 24] |
#                    VideoController.VCN_TXP2[p2 >>> 24] |
#                    VideoController.VCN_TXP1[p1 >>> 24] |
#                    VideoController.VCN_TXP0[p0 >>> 24]);  //符号なし右シフトで&255を省略
#          tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置
#          (ローカル変数宣言)
#          XEiJ.pnlBM[da] = (k=0のARGB);
#          XEiJ.pnlBM[da + 1] = (k=1のARGB);
#          XEiJ.pnlBM[da + 2] = (k=2のARGB);
#          XEiJ.pnlBM[da + 3] = (k=3のARGB);
#          XEiJ.pnlBM[da + 4] = (k=4のARGB);
#          XEiJ.pnlBM[da + 5] = (k=5のARGB);
#          XEiJ.pnlBM[da + 6] = (k=6のARGB);
#          XEiJ.pnlBM[da + 7] = (k=7のARGB);
#          (更新8)
#          da += 8;
#        }  //while da<db
#      }  //if ts==0
#
#  E  512ドット16色
#    512ドット16色準備
#      (e1p()があるとき)
#      int pn = VideoController.vcnReg2Curr & 3;  //1番目のパレットのGVRAMページ番号
#      int gx1st = CRTC.crtR12GrXCurr[pn];
#      int gy1st = VideoController.vcnVisible1st + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);
#      (e2p()またはe2q()があるとき)
#      pn = VideoController.vcnReg2Curr >> 2 & 3;  //2番目のパレットのGVRAMページ番号
#      int gx2nd = CRTC.crtR12GrXCurr[pn];
#      (e2p()があるとき)
#      int gy2nd = VideoController.vcnVisible2nd + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);
#      (e2q()があるとき)
#      int gz2nd = VideoController.vcnHidden2nd + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);  //ONとみなす
#      (e3p()があるとき)
#      pn = VideoController.vcnReg2Curr >> 4 & 3;  //3番目のパレットのGVRAMページ番号
#      int gx3rd = CRTC.crtR12GrXCurr[pn];
#      int gy3rd = VideoController.vcnVisible3rd + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);
#      (e4p()があるとき)
#      pn = VideoController.vcnReg2Curr >> 6 & 3;  //4番目のパレットのGVRAMページ番号
#      int gx4th = CRTC.crtR12GrXCurr[pn];
#      int gy4th = VideoController.vcnVisible4th + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);
#    512ドット16色準備half
#      (e1p()があるとき)
#      gx1st += half;
#      (e2p()またはe2q()があるとき)
#      gx2nd += half;
#      (e3p()があるとき)
#      gx3rd += half;
#      (e4p()があるとき)
#      gx4th += half;
#    512ドット16色パレット e1p()
#      k=0  GraphicScreen.graM4[gy1st | gx1st & 511]
#      k=1  GraphicScreen.graM4[gy1st | gx1st + 1 & 511]
#      k=2  GraphicScreen.graM4[gy1st | gx1st + 2 & 511]
#      k=3  GraphicScreen.graM4[gy1st | gx1st + 3 & 511]
#      k=4  GraphicScreen.graM4[gy1st | gx1st + 4 & 511]
#      k=5  GraphicScreen.graM4[gy1st | gx1st + 5 & 511]
#      k=6  GraphicScreen.graM4[gy1st | gx1st + 6 & 511]
#      k=7  GraphicScreen.graM4[gy1st | gx1st + 7 & 511]
#    512ドット16色パレット e2p()
#      k=0  GraphicScreen.graM4[gy2nd | gx2nd & 511]
#      k=1  GraphicScreen.graM4[gy2nd | gx2nd + 1 & 511]
#      k=2  GraphicScreen.graM4[gy2nd | gx2nd + 2 & 511]
#      k=3  GraphicScreen.graM4[gy2nd | gx2nd + 3 & 511]
#      k=4  GraphicScreen.graM4[gy2nd | gx2nd + 4 & 511]
#      k=5  GraphicScreen.graM4[gy2nd | gx2nd + 5 & 511]
#      k=6  GraphicScreen.graM4[gy2nd | gx2nd + 6 & 511]
#      k=7  GraphicScreen.graM4[gy2nd | gx2nd + 7 & 511]
#    512ドット16色パレット(ONとみなす) e2q()
#      k=0  GraphicScreen.graM4[gz2nd | gx2nd & 511]
#      k=1  GraphicScreen.graM4[gz2nd | gx2nd + 1 & 511]
#      k=2  GraphicScreen.graM4[gz2nd | gx2nd + 2 & 511]
#      k=3  GraphicScreen.graM4[gz2nd | gx2nd + 3 & 511]
#      k=4  GraphicScreen.graM4[gz2nd | gx2nd + 4 & 511]
#      k=5  GraphicScreen.graM4[gz2nd | gx2nd + 5 & 511]
#      k=6  GraphicScreen.graM4[gz2nd | gx2nd + 6 & 511]
#      k=7  GraphicScreen.graM4[gz2nd | gx2nd + 7 & 511]
#    512ドット16色パレット e3p()
#      k=0  GraphicScreen.graM4[gy3rd | gx3rd & 511]
#      k=1  GraphicScreen.graM4[gy3rd | gx3rd + 1 & 511]
#      k=2  GraphicScreen.graM4[gy3rd | gx3rd + 2 & 511]
#      k=3  GraphicScreen.graM4[gy3rd | gx3rd + 3 & 511]
#      k=4  GraphicScreen.graM4[gy3rd | gx3rd + 4 & 511]
#      k=5  GraphicScreen.graM4[gy3rd | gx3rd + 5 & 511]
#      k=6  GraphicScreen.graM4[gy3rd | gx3rd + 6 & 511]
#      k=7  GraphicScreen.graM4[gy3rd | gx3rd + 7 & 511]
#    512ドット16色パレット e4p()
#      k=0  GraphicScreen.graM4[gy4th | gx4th & 511]
#      k=1  GraphicScreen.graM4[gy4th | gx4th + 1 & 511]
#      k=2  GraphicScreen.graM4[gy4th | gx4th + 2 & 511]
#      k=3  GraphicScreen.graM4[gy4th | gx4th + 3 & 511]
#      k=4  GraphicScreen.graM4[gy4th | gx4th + 4 & 511]
#      k=5  GraphicScreen.graM4[gy4th | gx4th + 5 & 511]
#      k=6  GraphicScreen.graM4[gy4th | gx4th + 6 & 511]
#      k=7  GraphicScreen.graM4[gy4th | gx4th + 7 & 511]
#    512ドット16色カラー epc(p)
#      VideoController.vcnPal16G8[p]
#    512ドット16色ARGB epo(p)
#      VideoController.vcnPal32G8[p]
#    512ドット16色更新1
#      (e1p()があるとき)
#        gx1st++;
#      (e2p()またはe2q()があるとき)
#        gx2nd++;
#      (e3p()があるとき)
#        gx3rd++;
#      (e4p()があるとき)
#        gx4th++;
#    512ドット16色更新8
#      (e1p()があるとき)
#        gx1st += 8;
#      (e2p()またはe2q()があるとき)
#        gx2nd += 8;
#      (e3p()があるとき)
#        gx3rd += 8;
#      (e4p()があるとき)
#        gx4th += 8;
#
#  F  512ドット256色
#    512ドット256色準備
#      (f1p()があるとき)
#      int pn = VideoController.vcnReg2Curr & 3;  //1番目のパレットのbit3-0のGVRAMページ番号
#      int gx1st = CRTC.crtR12GrXCurr[pn];
#      int gy1st = VideoController.vcnVisible1st + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);
#      pn = VideoController.vcnReg2Curr >> 2 & 3;  //1番目のパレットのbit7-4のGVRAMページ番号
#      int gx2nd = CRTC.crtR12GrXCurr[pn];
#      int gy2nd = VideoController.vcnVisible2nd + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);
#      (f2p()またはf2q()があるとき)
#      pn = VideoController.vcnReg2Curr >> 4 & 3;  //2番目のパレットのbit3-0のGVRAMページ番号
#      int gx3rd = CRTC.crtR12GrXCurr[pn];
#      (f2p()があるとき)
#      int gy3rd = VideoController.vcnVisible3rd + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);
#      (f2q()があるとき)
#      int gz3rd = VideoController.vcnHidden3rd + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);
#      (f2p()またはf2q()があるとき)
#      pn = VideoController.vcnReg2Curr >> 6 & 3;  //2番目のパレットのbit7-4のGVRAMページ番号
#      int gx4th = CRTC.crtR12GrXCurr[pn];
#      (f2p()があるとき)
#      int gy4th = VideoController.vcnVisible4th + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);
#      (f2q()があるとき)
#      int gz4th = VideoController.vcnHidden4th + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);
#    512ドット256色準備half
#      (f1p()があるとき)
#      gx1st += half;
#      gx2nd += half;
#      (f2p()またはf2q()があるとき)
#      gx3rd += half;
#      gx4th += half;
#    512ドット256色パレット f1p()
#      k=0  (GraphicScreen.graM4[gy2nd | gx2nd & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st & 511])
#      k=1  (GraphicScreen.graM4[gy2nd | gx2nd + 1 & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st + 1 & 511])
#      k=2  (GraphicScreen.graM4[gy2nd | gx2nd + 2 & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st + 2 & 511])
#      k=3  (GraphicScreen.graM4[gy2nd | gx2nd + 3 & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st + 3 & 511])
#      k=4  (GraphicScreen.graM4[gy2nd | gx2nd + 4 & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st + 4 & 511])
#      k=5  (GraphicScreen.graM4[gy2nd | gx2nd + 5 & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st + 5 & 511])
#      k=6  (GraphicScreen.graM4[gy2nd | gx2nd + 6 & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st + 6 & 511])
#      k=7  (GraphicScreen.graM4[gy2nd | gx2nd + 7 & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st + 7 & 511])
#    512ドット256色パレット f2p()
#      k=0  (GraphicScreen.graM4[gy4th | gx4th & 511] << 4 |
#            GraphicScreen.graM4[gy3rd | gx3rd & 511])
#      k=1  (GraphicScreen.graM4[gy4th | gx4th + 1 & 511] << 4 |
#            GraphicScreen.graM4[gy3rd | gx3rd + 1 & 511])
#      k=2  (GraphicScreen.graM4[gy4th | gx4th + 2 & 511] << 4 |
#            GraphicScreen.graM4[gy3rd | gx3rd + 2 & 511])
#      k=3  (GraphicScreen.graM4[gy4th | gx4th + 3 & 511] << 4 |
#            GraphicScreen.graM4[gy3rd | gx3rd + 3 & 511])
#      k=4  (GraphicScreen.graM4[gy4th | gx4th + 4 & 511] << 4 |
#            GraphicScreen.graM4[gy3rd | gx3rd + 4 & 511])
#      k=5  (GraphicScreen.graM4[gy4th | gx4th + 5 & 511] << 4 |
#            GraphicScreen.graM4[gy3rd | gx3rd + 5 & 511])
#      k=6  (GraphicScreen.graM4[gy4th | gx4th + 6 & 511] << 4 |
#            GraphicScreen.graM4[gy3rd | gx3rd + 6 & 511])
#      k=7  (GraphicScreen.graM4[gy4th | gx4th + 7 & 511] << 4 |
#            GraphicScreen.graM4[gy3rd | gx3rd + 7 & 511])
#    512ドット256色パレット(ONとみなす) f2q()
#      k=0  (GraphicScreen.graM4[gz4th | gx4th & 511] << 4 |
#            GraphicScreen.graM4[gz3rd | gx3rd & 511])
#      k=1  (GraphicScreen.graM4[gz4th | gx4th + 1 & 511] << 4 |
#            GraphicScreen.graM4[gz3rd | gx3rd + 1 & 511])
#      k=2  (GraphicScreen.graM4[gz4th | gx4th + 2 & 511] << 4 |
#            GraphicScreen.graM4[gz3rd | gx3rd + 2 & 511])
#      k=3  (GraphicScreen.graM4[gz4th | gx4th + 3 & 511] << 4 |
#            GraphicScreen.graM4[gz3rd | gx3rd + 3 & 511])
#      k=4  (GraphicScreen.graM4[gz4th | gx4th + 4 & 511] << 4 |
#            GraphicScreen.graM4[gz3rd | gx3rd + 4 & 511])
#      k=5  (GraphicScreen.graM4[gz4th | gx4th + 5 & 511] << 4 |
#            GraphicScreen.graM4[gz3rd | gx3rd + 5 & 511])
#      k=6  (GraphicScreen.graM4[gz4th | gx4th + 6 & 511] << 4 |
#            GraphicScreen.graM4[gz3rd | gx3rd + 6 & 511])
#      k=7  (GraphicScreen.graM4[gz4th | gx4th + 7 & 511] << 4 |
#            GraphicScreen.graM4[gz3rd | gx3rd + 7 & 511])
#    512ドット256色カラー fpc(p)
#      VideoController.vcnPal16G8[p]
#    512ドット256色ARGB fpo(p)
#      VideoController.vcnPal32G8[p]
#    512ドット256色更新1
#      (f1p()があるとき)
#        gx1st++;
#        gx2nd++;
#      (f2p()またはf2q()があるとき)
#        gx3rd++;
#        gx4th++;
#    512ドット256色更新8
#      (f1p()があるとき)
#        gx1st += 8;
#        gx2nd += 8;
#      (f2p()またはf2q()があるとき)
#        gx3rd += 8;
#        gx4th += 8;
#
#  G  512ドット65536色
#    512ドット65536色準備
#      (g1p()があるとき)
#      int pn = VideoController.vcnReg2Curr & 3;  //1番目のパレットのbit3-0のGVRAMページ番号
#      int gx1st = CRTC.crtR12GrXCurr[pn];
#      int gy1st = (pn << 18) + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);
#      pn = VideoController.vcnReg2Curr >> 2 & 3;  //1番目のパレットのbit7-4のGVRAMページ番号
#      int gx2nd = CRTC.crtR12GrXCurr[pn];
#      int gy2nd = (pn << 18) + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);
#      pn = VideoController.vcnReg2Curr >> 4 & 3;  //1番目のパレットのbit11-8のGVRAMページ番号
#      int gx3rd = CRTC.crtR12GrXCurr[pn];
#      int gy3rd = (pn << 18) + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);
#      pn = VideoController.vcnReg2Curr >> 6 & 3;  //1番目のパレットのbit15-12のGVRAMページ番号
#      int gx4th = CRTC.crtR12GrXCurr[pn];
#      int gy4th = (pn << 18) + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);
#    512ドット65536色準備half
#      (g1p()があるとき)
#      gx1st += half;
#      gx2nd += half;
#      gx3rd += half;
#      gx4th += half;
#    512ドット65536色パレット g1p()
#      k=0  (GraphicScreen.graM4[gy4th | gx4th & 511] << 12 |
#            GraphicScreen.graM4[gy3rd | gx3rd & 511] << 8 |
#            GraphicScreen.graM4[gy2nd | gx2nd & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st & 511])
#      k=1  (GraphicScreen.graM4[gy4th | gx4th + 1 & 511] << 12 |
#            GraphicScreen.graM4[gy3rd | gx3rd + 1 & 511] << 8 |
#            GraphicScreen.graM4[gy2nd | gx2nd + 1 & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st + 1 & 511])
#      k=2  (GraphicScreen.graM4[gy4th | gx4th + 2 & 511] << 12 |
#            GraphicScreen.graM4[gy3rd | gx3rd + 2 & 511] << 8 |
#            GraphicScreen.graM4[gy2nd | gx2nd + 2 & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st + 2 & 511])
#      k=3  (GraphicScreen.graM4[gy4th | gx4th + 3 & 511] << 12 |
#            GraphicScreen.graM4[gy3rd | gx3rd + 3 & 511] << 8 |
#            GraphicScreen.graM4[gy2nd | gx2nd + 3 & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st + 3 & 511])
#      k=4  (GraphicScreen.graM4[gy4th | gx4th + 4 & 511] << 12 |
#            GraphicScreen.graM4[gy3rd | gx3rd + 4 & 511] << 8 |
#            GraphicScreen.graM4[gy2nd | gx2nd + 4 & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st + 4 & 511])
#      k=5  (GraphicScreen.graM4[gy4th | gx4th + 5 & 511] << 12 |
#            GraphicScreen.graM4[gy3rd | gx3rd + 5 & 511] << 8 |
#            GraphicScreen.graM4[gy2nd | gx2nd + 5 & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st + 5 & 511])
#      k=6  (GraphicScreen.graM4[gy4th | gx4th + 6 & 511] << 12 |
#            GraphicScreen.graM4[gy3rd | gx3rd + 6 & 511] << 8 |
#            GraphicScreen.graM4[gy2nd | gx2nd + 6 & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st + 6 & 511])
#      k=7  (GraphicScreen.graM4[gy4th | gx4th + 7 & 511] << 12 |
#            GraphicScreen.graM4[gy3rd | gx3rd + 7 & 511] << 8 |
#            GraphicScreen.graM4[gy2nd | gx2nd + 7 & 511] << 4 |
#            GraphicScreen.graM4[gy1st | gx1st + 7 & 511])
#    512ドット65536色カラー gpc(p,q)
#      (VideoController.vcnPal8G16H[p >> 8] |
#       VideoController.vcnPal8G16L[q & 255])
#    512ドット65536色ARGB gpo(p,q)
#      VideoController.vcnPalTbl[VideoController.vcnPal8G16H[p >> 8] |
#                                VideoController.vcnPal8G16L[q & 255]]
#    512ドット65536色更新1
#      (g1p()があるとき)
#        gx1st++;
#        gx2nd++;
#        gx3rd++;
#        gx4th++;
#    512ドット65536色更新8
#      (g1p()があるとき)
#        gx1st += 8;
#        gx2nd += 8;
#        gx3rd += 8;
#        gx4th += 8;
#
#  H  1024ドット16色
#    1024ドット16色パレット h1p()
#      k=0  GraphicScreen.graM4[ga]
#      k=1  GraphicScreen.graM4[ga + 1]
#      k=2  GraphicScreen.graM4[ga + 2]
#      k=3  GraphicScreen.graM4[ga + 3]
#      k=4  GraphicScreen.graM4[ga + 4]
#      k=5  GraphicScreen.graM4[ga + 5]
#      k=6  GraphicScreen.graM4[ga + 6]
#      k=7  GraphicScreen.graM4[ga + 7]
#    1024ドット16色カラー hpc(p)
#      VideoController.vcnPal16G8[p]
#    1024ドット16色ARGB hpo(p)
#      VideoController.vcnPal32G8[p]
#    1024ドット16色構造
#      (準備)
#      int gx = CRTC.crtR12GrXCurr[0];  //1024ドット16色x座標。溢れは無視する
#      int gy = CRTC.crtR13GrYZero[0] + src;  //1024ドット16色y座標。溢れは無視する
#      int ga0 = ((gy & 511) << 9);  //x=0,y&=511の1024ドット16色アドレス
#      int gt = VideoController.vcnReg2Curr >> (gy >> 7 & 4);  //y<512?G2nd|G1st:G4th|G3rd
#      int da = dst << XEiJ.PNL_BM_OFFSET_BITS;  //ARGB出力インデックス
#      int db = da + XEiJ.pnlScreenWidth;  //ARGB出力インデックスの終了位置
#      if (rh) {
#        int half = XEiJ.pnlScreenWidth >> 4 << 3;
#        (準備half)
#        gx += half;
#        da += half;
#      }
#      int ga = ga0 + ((gt >> (gx >> 8 & 2) & 3) << 18) + (gx & 511);  //1024ドットアドレス
#      while (da < db) {
#        int dw = Math.min (db - da, (512 - (gx & 511)) & -8);  //今回の幅。8の倍数
#        gx += dw;  //次回の1024ドットx座標
#        int dc = da + dw;  //今回のARGB出力インデックスの終了位置
#        while (da < dc) {
#          (ローカル変数宣言)
#          XEiJ.pnlBM[da] = (k=0のARGB);
#          XEiJ.pnlBM[da + 1] = (k=1のARGB);
#          XEiJ.pnlBM[da + 2] = (k=2のARGB);
#          XEiJ.pnlBM[da + 3] = (k=3のARGB);
#          XEiJ.pnlBM[da + 4] = (k=4のARGB);
#          XEiJ.pnlBM[da + 5] = (k=5のARGB);
#          XEiJ.pnlBM[da + 6] = (k=6のARGB);
#          XEiJ.pnlBM[da + 7] = (k=7のARGB);
#          (更新8)
#          ga += 8;
#          da += 8;
#        }  //while da<dc
#        if (da < db) {
#          for (int k = 0; k < 8; k++) {
#            if ((gx & 511) == 0) {  //gxが512の倍数のとき
#              ga = ga0 + ((gt >> (gx >> 8 & 2) & 3) << 18);  //gaを再計算する
#            }
#            gx++;
#            (ローカル変数宣言)
#            XEiJ.pnlBM[da] = (k=0のARGB);
#            (更新1)
#            ga++;
#            da++;
#          }  //for k
#        }  //if da<db
#      }  //while da<db
#    テキスト・1024ドット16色構造
#      (準備)
#      int ty = CRTC.crtR11TxYZero + src & 1023;  //ラスタ
#      int tc = (ty & CRTC.crtMask3) << 7 | CRTC.crtR10TxXCurr >> 3;  //テキスト桁位置
#      int ta0 = 0x00e00000 + ((ty & CRTC.crtMaskMinus4) << 7);  //ラスタブロックアドレス
#      int ta1 = 0x00020000 + ta0;
#      int ta2 = 0x00040000 + ta0;
#      int ta3 = 0x00060000 + ta0;
#      int ts = CRTC.crtR10TxXCurr & 7;  //テキスト桁境界からのずれ
#      int gx = CRTC.crtR12GrXCurr[0];  //1024ドット16色x座標。溢れは無視する
#      int gy = CRTC.crtR13GrYZero[0] + src;  //1024ドット16色y座標。溢れは無視する
#      int ga0 = ((gy & 511) << 9);  //x=0,y&=511の1024ドット16色アドレス
#      int gt = VideoController.vcnReg2Curr >> (gy >> 7 & 4);  //y<512?G2nd|G1st:G4th|G3rd
#      int da = dst << XEiJ.PNL_BM_OFFSET_BITS;  //ARGB出力インデックス
#      int db = da + XEiJ.pnlScreenWidth;  //ARGB出力インデックスの終了位置
#      if (rh) {
#        int half = XEiJ.pnlScreenWidth >> 4 << 3;
#        (準備half)
#        tc = tc + (half >> 3) & CRTC.crtMask511;
#        gx += half;
#        da += half;
#      }
#      int ga = ga0 + ((gt >> (gx >> 8 & 2) & 3) << 18) + (gx & 511);  //1024ドットアドレス
#      if (ts == 0) {  //テキスト桁境界に合っているとき
#        while (da < db) {
#          int dw = Math.min (db - da, (512 - (gx & 511)) & -8);  //今回の幅。8の倍数
#          gx += dw;  //次回の1024ドットx座標
#          int dc = da + dw;  //今回のARGB出力インデックスの終了位置
#          while (da < dc) {
#            int tp = (VideoController.VCN_TXP3[MainMemory.mmrM8[ta3 + tc] & 255] |
#                      VideoController.VCN_TXP2[MainMemory.mmrM8[ta2 + tc] & 255] |
#                      VideoController.VCN_TXP1[MainMemory.mmrM8[ta1 + tc] & 255] |
#                      VideoController.VCN_TXP0[MainMemory.mmrM8[ta0 + tc] & 255]);
#            tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置
#            (ローカル変数宣言)
#            XEiJ.pnlBM[da] = (k=0のARGB);
#            XEiJ.pnlBM[da + 1] = (k=1のARGB);
#            XEiJ.pnlBM[da + 2] = (k=2のARGB);
#            XEiJ.pnlBM[da + 3] = (k=3のARGB);
#            XEiJ.pnlBM[da + 4] = (k=4のARGB);
#            XEiJ.pnlBM[da + 5] = (k=5のARGB);
#            XEiJ.pnlBM[da + 6] = (k=6のARGB);
#            XEiJ.pnlBM[da + 7] = (k=7のARGB);
#            (更新8)
#            ga += 8;
#            da += 8;
#          }  //while da<dc
#          if (da < db) {
#            int tp = (VideoController.VCN_TXP3[MainMemory.mmrM8[ta3 + tc] & 255] |
#                      VideoController.VCN_TXP2[MainMemory.mmrM8[ta2 + tc] & 255] |
#                      VideoController.VCN_TXP1[MainMemory.mmrM8[ta1 + tc] & 255] |
#                      VideoController.VCN_TXP0[MainMemory.mmrM8[ta0 + tc] & 255]);
#            tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置
#            for (int k = 0; k < 8; k++) {
#              if ((gx & 511) == 0) {  //gxが512の倍数のとき
#                ga = ga0 + ((gt >> (gx >> 8 & 2) & 3) << 18);  //gaを再計算する
#              }
#              gx++;
#              (ローカル変数宣言)
#              XEiJ.pnlBM[da] = (k=0のARGB);
#              (更新1)
#              tp <<= 4;
#              ga++;
#              da++;
#            }  //for k
#          }  //if da<db
#        }  //while da<db
#      } else {  //テキスト桁境界に合っていないとき
#        //                                                               ts=1のとき
#        int tt = ts + 8;                                               //tt=9
#        ts += 16;                                                      //ts=17
#        //                                                               ........ ........ ........ 01234567  m8[ta0+tc]
#        int p0 = MainMemory.mmrM8[ta0 + tc] << ts;                     //.......0 1234567_ ________ ________  p0=m8[ta0+tc]<<ts
#        int p1 = MainMemory.mmrM8[ta1 + tc] << ts;
#        int p2 = MainMemory.mmrM8[ta2 + tc] << ts;
#        int p3 = MainMemory.mmrM8[ta3 + tc] << ts;
#        tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置
#        while (da < db) {
#          int dw = Math.min (db - da, (512 - (gx & 511)) & -8);  //今回の幅。8の倍数
#          gx += dw;  //次回の1024ドットx座標
#          int dc = da + dw;  //今回のARGB出力インデックスの終了位置
#          while (da < dc) {
#            //                                                           ........ ........ .1234567 ________  p0>>tt
#            //                                                           ........ ........ .1234567 89abcdef  p0>>tt|m8[ta0+tc]&255
#            p0 = (p0 >> tt | MainMemory.mmrM8[ta0 + tc] & 255) << ts;  //12345678 9abcdef_ ________ ________  p0=(p0>>tt|m8[ta0+tc]&255)<<ts
#            p1 = (p1 >> tt | MainMemory.mmrM8[ta1 + tc] & 255) << ts;  //~~~~~~~~
#            p2 = (p2 >> tt | MainMemory.mmrM8[ta2 + tc] & 255) << ts;  //ここを使う
#            p3 = (p3 >> tt | MainMemory.mmrM8[ta3 + tc] & 255) << ts;
#            int tp = (VideoController.VCN_TXP3[p3 >>> 24] |
#                      VideoController.VCN_TXP2[p2 >>> 24] |
#                      VideoController.VCN_TXP1[p1 >>> 24] |
#                      VideoController.VCN_TXP0[p0 >>> 24]);  //符号なし右シフトで&255を省略
#            tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置
#            (ローカル変数宣言)
#            XEiJ.pnlBM[da] = (k=0のARGB);
#            XEiJ.pnlBM[da + 1] = (k=1のARGB);
#            XEiJ.pnlBM[da + 2] = (k=2のARGB);
#            XEiJ.pnlBM[da + 3] = (k=3のARGB);
#            XEiJ.pnlBM[da + 4] = (k=4のARGB);
#            XEiJ.pnlBM[da + 5] = (k=5のARGB);
#            XEiJ.pnlBM[da + 6] = (k=6のARGB);
#            XEiJ.pnlBM[da + 7] = (k=7のARGB);
#            (更新8)
#            ga += 8;
#            da += 8;
#          }  //while da<dc
#          if (da < db) {
#            //                                                           ........ ........ .1234567 ________  p0>>tt
#            //                                                           ........ ........ .1234567 89abcdef  p0>>tt|m8[ta0+tc]&255
#            p0 = (p0 >> tt | MainMemory.mmrM8[ta0 + tc] & 255) << ts;  //12345678 9abcdef_ ________ ________  p0=(p0>>tt|m8[ta0+tc]&255)<<ts
#            p1 = (p1 >> tt | MainMemory.mmrM8[ta1 + tc] & 255) << ts;  //~~~~~~~~
#            p2 = (p2 >> tt | MainMemory.mmrM8[ta2 + tc] & 255) << ts;  //ここを使う
#            p3 = (p3 >> tt | MainMemory.mmrM8[ta3 + tc] & 255) << ts;
#            int tp = (VideoController.VCN_TXP3[p3 >>> 24] |
#                      VideoController.VCN_TXP2[p2 >>> 24] |
#                      VideoController.VCN_TXP1[p1 >>> 24] |
#                      VideoController.VCN_TXP0[p0 >>> 24]);  //符号なし右シフトで&255を省略
#            tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置
#            for (int k = 0; k < 8; k++) {
#              if ((gx & 511) == 0) {  //gxが512の倍数のとき
#                ga = ga0 + ((gt >> (gx >> 8 & 2) & 3) << 18);  //gaを再計算する
#              }
#              gx++;
#              (ローカル変数宣言)
#              XEiJ.pnlBM[da] = (k=0のARGB);
#              (更新1)
#              tp <<= 4;
#              ga++;
#              da++;
#            }  //for k
#          }  //if da<db
#        }  //while da<db
#        ts -= 16;                                                      //ts=1
#      }  //if ts==0
#
#  I  1024ドット256色
#    1024ドット256色パレット i1p()
#      k=0  (GraphicScreen.graM4[ga + 0x100000] << 4 |
#            GraphicScreen.graM4[ga           ])
#      k=1  (GraphicScreen.graM4[ga + 0x100001] << 4 |
#            GraphicScreen.graM4[ga + 0x000001])
#      k=2  (GraphicScreen.graM4[ga + 0x100002] << 4 |
#            GraphicScreen.graM4[ga + 0x000002])
#      k=3  (GraphicScreen.graM4[ga + 0x100003] << 4 |
#            GraphicScreen.graM4[ga + 0x000003])
#      k=4  (GraphicScreen.graM4[ga + 0x100004] << 4 |
#            GraphicScreen.graM4[ga + 0x000004])
#      k=5  (GraphicScreen.graM4[ga + 0x100005] << 4 |
#            GraphicScreen.graM4[ga + 0x000005])
#      k=6  (GraphicScreen.graM4[ga + 0x100006] << 4 |
#            GraphicScreen.graM4[ga + 0x000006])
#      k=7  (GraphicScreen.graM4[ga + 0x100007] << 4 |
#            GraphicScreen.graM4[ga + 0x000007])
#    1024ドット256色カラー ipc(p)
#      VideoController.vcnPal16G8[p]
#    1024ドット256色ARGB ipo(p)
#      VideoController.vcnPal32G8[p]
#    1024ドット256色構造
#      1024ドット16色構造と同じ
#      int ga0 = ((gy & 511) << 9);  //x=0,y&=511の1024ドット16色アドレス
#        ↓
#      int ga0 = ((gy & 511) << 9);  //x=0,y&=511の1024ドット256色アドレス
#
#  J  1024ドット65536色
#    1024ドット65536色パレット j1p()
#      k=0  (GraphicScreen.graM4[ga + 0x300000] << 12 |
#            GraphicScreen.graM4[ga + 0x200000] << 8 |
#            GraphicScreen.graM4[ga + 0x100000] << 4 |
#            GraphicScreen.graM4[ga           ])
#      k=1  (GraphicScreen.graM4[ga + 0x300001] << 12 |
#            GraphicScreen.graM4[ga + 0x200001] << 8 |
#            GraphicScreen.graM4[ga + 0x100001] << 4 |
#            GraphicScreen.graM4[ga + 0x000001])
#      k=2  (GraphicScreen.graM4[ga + 0x300002] << 12 |
#            GraphicScreen.graM4[ga + 0x200002] << 8 |
#            GraphicScreen.graM4[ga + 0x100002] << 4 |
#            GraphicScreen.graM4[ga + 0x000002])
#      k=3  (GraphicScreen.graM4[ga + 0x300003] << 12 |
#            GraphicScreen.graM4[ga + 0x200003] << 8 |
#            GraphicScreen.graM4[ga + 0x100003] << 4 |
#            GraphicScreen.graM4[ga + 0x000003])
#      k=4  (GraphicScreen.graM4[ga + 0x300004] << 12 |
#            GraphicScreen.graM4[ga + 0x200004] << 8 |
#            GraphicScreen.graM4[ga + 0x100004] << 4 |
#            GraphicScreen.graM4[ga + 0x000004])
#      k=5  (GraphicScreen.graM4[ga + 0x300005] << 12 |
#            GraphicScreen.graM4[ga + 0x200005] << 8 |
#            GraphicScreen.graM4[ga + 0x100005] << 4 |
#            GraphicScreen.graM4[ga + 0x000005])
#      k=6  (GraphicScreen.graM4[ga + 0x300006] << 12 |
#            GraphicScreen.graM4[ga + 0x200006] << 8 |
#            GraphicScreen.graM4[ga + 0x100006] << 4 |
#            GraphicScreen.graM4[ga + 0x000006])
#      k=7  (GraphicScreen.graM4[ga + 0x300007] << 12 |
#            GraphicScreen.graM4[ga + 0x200007] << 8 |
#            GraphicScreen.graM4[ga + 0x100007] << 4 |
#            GraphicScreen.graM4[ga + 0x000007])
#    1024ドット65536色カラー jpc(p,q)
#      (VideoController.vcnPal8G16H[p >> 8] |
#       VideoController.vcnPal8G16L[q & 255])
#    1024ドット65536色ARGB jpo(p,q)
#      VideoController.vcnPalTbl[VideoController.vcnPal8G16H[p >> 8] |
#                                VideoController.vcnPal8G16L[q & 255]]
#    1024ドット65536色構造
#      1024ドット16色構造と同じ
#      int ga0 = ((gy & 511) << 9);  //x=0,y&=511の1024ドット16色アドレス
#        ↓
#      int ga0 = ((gy & 511) << 9);  //x=0,y&=511の1024ドット65536色アドレス
#



#================================================================================
#基本モードと拡張モードに対応するソースコードを生成する
sub generate {
  my ($keyword, $xword, $xmap) = @_;
  push @{$xmap->{$keyword}}, $xword;
  my $xkeyword = $xword eq '' ? $keyword : "${keyword}_$xword";
  my $regs = make_regs ($keyword, $xword);
  my $text = join '＞', map { $KEY_TEXT{$_} } split /(?<=[0-9A-Za-z])(?![0-9])/, $keyword;
  my $mode = {
    nonzero1st => 0,  #1=1番目のパレットは0ではない
    zero1st => 0,  #1=1番目のパレットは0
    even1st => 0,  #1=1番目のパレットは偶数。nonzero1stのとき2以上の偶数
    odd1st => 0,  #1=1番目のパレットは奇数。nonzero1stのとき3以上の奇数
    one1st => 0,  #1=1番目のパレットは1。nonzero1st,odd1st
    nonzero2nd => 0,  #1=2番目のパレットは0ではない
    zero2nd => 0,  #1=2番目のパレットは0
    even2nd => 0,  #1=2番目のパレットは偶数。nonzero2ndのとき2以上の偶数
    odd2nd => 0,  #1=2番目のパレットは奇数。nonzero2ndのとき3以上の奇数
    one2nd => 0,  #1=2番目のパレットは1。nonzero2nd,odd2nd
    nonzero3rd => 0,  #1=3番目のパレットは0ではない
    zero3rd => 0,  #1=3番目のパレットは0
    even3rd => 0,  #1=3番目のパレットは偶数。nonzero3rdのとき2以上の偶数
    odd3rd => 0,  #1=3番目のパレットは奇数。nonzero3rdのとき3以上の奇数
    one3rd => 0,  #1=3番目のパレットは1。nonzero3rd,odd3rd
    nonzero4th => 0,  #1=4番目のパレットは0ではない
    zero4th => 0,  #1=4番目のパレットは0
    even4th => 0,  #1=4番目のパレットは偶数。nonzero4thのとき2以上の偶数
    odd4th => 0,  #1=4番目のパレットは奇数。nonzero4thのとき3以上の奇数
    one4th => 0,  #1=4番目のパレットは1。nonzero4th,odd4th
    toeven => 0,  #1=グラフィックパレットを偶数化する。even1st..4thのときそれぞれ1..4番目のパレットは偶数化する必要がない
    toodd => 0,  #1=グラフィックパレットを奇数化する。odd1st..4thのときそれぞれ1..4番目のパレットは奇数化する必要がない
    xword => $xword,  #拡張ワード
    encode => 0  #0=手順,1=コード
    };
  #
  my @body = ();
  push @body, "\n";
  push @body, "  //================================================================================\n";
  push @body, "  //$xkeyword ($regs)\n";
  push @body, "  //  概要\n";
  push @body, "  //    $keyword  $text\n";
  if ($xword eq '') {
    push @body, "  //    拡張なし\n";
  } else {
    push @body, "  //    $xword  $X_TEXT{$xword}\n";
  }
  push @body, "  //  手順\n";
  push @body, pass1 ('  //    ', $keyword, $mode);
  foreach my $key (qw(
    nonzero1st
    zero1st
    even1st
    odd1st
    one1st
    nonzero2nd
    zero2nd
    even2nd
    odd2nd
    one2nd
    nonzero3rd
    zero3rd
    even3rd
    odd3rd
    one3rd
    nonzero4th
    zero4th
    even4th
    odd4th
    one4th
    )) {
    $mode->{$key} == 0 or die "$keyword $key!=0";
  }
  $mode->{'encode'} = 1;
  my $code1 = join ('', pass1 ('', $keyword, $mode));
  $mode->{'encode'} = 0;
  push @body, "  //  中間コード1\n";
  push @body, "  //    $code1\n";
  my $tree = pass2 ($code1);
  my $code2 = &{$tree->{'tostring'}} ($tree);
  push @body, "  //  中間コード2\n";
  push @body, "  //    $code2\n";
  check_node ($tree);
  pass3 ($tree);
  my $code3 = &{$tree->{'tostring'}} ($tree);
  push @body, "  //  中間コード3\n";
  push @body, "  //    $code3\n";
  check_node ($tree);
  pass4 ($tree);
  my $code4 = &{$tree->{'tostring'}} ($tree);
  push @body, "  //  中間コード4\n";
  push @body, "  //    $code4\n";
  check_node ($tree);
  pass5 ($tree);
  my $code5 = &{$tree->{'tostring'}} ($tree);
  push @body, "  //  中間コード5\n";
  push @body, "  //    $code5\n";
  check_node ($tree);
  $tree = pass6 ($tree);
  my $code6 = &{$tree->{'tostring'}} ($tree);
  push @body, "  //  中間コード6\n";
  push @body, "  //    $code6\n";
  check_node ($tree);
  #
  my $status;
  my @draw = ();
  for (my $k = 0; $k < 8; $k++) {
    my $line = new_assignment (new_parenthesis ($tree),  #右辺
                               new_arrayaccess (new_id ('XEiJ.pnlBM'),
                                                $k == 0 ?
                                                new_id ('da') :
                                                new_addition (new_id ('da'),
                                                              new_int ($k))));  #左辺
    $status = {
      buffer => [],  #出力バッファ
      column => 0,  #現在の桁位置。-1=改行済みだがインデントされていない
      indent => 0,  #インデント。次に改行したとき行頭に出力する空白の数
      stack => [],  #インデントのスタック
      k => $k
        #id_<id>  1=idが使われた
      };
    $line = &{$line->{'evaluate'}} ($line, $status);
    check_node ($line);
    &{$line->{'tocode'}} ($line, $status);
    push @draw, [split /(?<=\n)/, join ('', @{$status->{'buffer'}}) . ";\n"];  #一旦連結して改行の直後で切り直す
  }
  my $draw0 = join '', @{$draw[0]};
  my $draw1 = join '', @{$draw[1]};
  #準備
  my @preparation = ();
  if ($draw0 eq $draw1) {
    push @preparation, "int cd = $draw0";
    @draw = ();
    for (my $k = 0; $k < 8; $k++) {
      my $pk = $k == 0 ? '' : ' + ' . $k;
      push @draw, ["XEiJ.pnlBM[da$pk] = cd;\n"];
    }
  }
  #準備half
  my @preparation_half = ();
  #ローカル変数宣言
  my @localvariable = ();
  if ($status->{'id_r'}) {
    push @localvariable, "int p, q, r;\n";
  } elsif ($status->{'id_q'}) {
    push @localvariable, "int p, q;\n";
  } elsif ($status->{'id_p'}) {
    push @localvariable, "int p;\n";
  }
  #更新1
  my @update1 = ();
  #更新8
  my @update8 = ();
  #スプライト
  if ($keyword =~ /S/) {
    push @preparation, "SpriteScreen.sprStep3 ();\n";
    push @preparation, "int sx = 16;  //スプライトx座標\n";
    push @preparation_half, "sx += half;\n";
    push @update1, "sx++;\n";
    push @update8, "sx += 8;\n";
  }
  #テキスト
  if ($keyword =~ /[Tt]/) {
  }
  #512ドット16色
  if ($keyword =~ /E/) {
    if ($status->{'id_e1p'}) {
      push @preparation, "int pn = VideoController.vcnReg2Curr & 3;  //1番目のパレットのGVRAMページ番号\n";
      push @preparation, "int gx1st = CRTC.crtR12GrXCurr[pn];\n";
      push @preparation, "int gy1st = VideoController.vcnVisible1st + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);\n";
      push @preparation_half, "gx1st += half;\n";
      push @update1, "gx1st++;\n";
      push @update8, "gx1st += 8;\n";
    }
    if ($status->{'id_e2p'} || $status->{'id_e2q'}) {
      push @preparation, "pn = VideoController.vcnReg2Curr >> 2 & 3;  //2番目のパレットのGVRAMページ番号\n";
      push @preparation, "int gx2nd = CRTC.crtR12GrXCurr[pn];\n";
      push @preparation_half, "gx2nd += half;\n";
      push @update1, "gx2nd++;\n";
      push @update8, "gx2nd += 8;\n";
    }
    if ($status->{'id_e2p'}) {
      push @preparation, "int gy2nd = VideoController.vcnVisible2nd + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);\n";
    }
    if ($status->{'id_e2q'}) {
      push @preparation, "int gz2nd = VideoController.vcnHidden2nd + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);  //ONとみなす\n";
    }
    if ($status->{'id_e3p'}) {
      push @preparation, "pn = VideoController.vcnReg2Curr >> 4 & 3;  //3番目のパレットのGVRAMページ番号\n";
      push @preparation, "int gx3rd = CRTC.crtR12GrXCurr[pn];\n";
      push @preparation, "int gy3rd = VideoController.vcnVisible3rd + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);\n";
      push @preparation_half, "gx3rd += half;\n";
      push @update1, "gx3rd++;\n";
      push @update8, "gx3rd += 8;\n";
    }
    if ($status->{'id_e4p'}) {
      push @preparation, "pn = VideoController.vcnReg2Curr >> 6 & 3;  //4番目のパレットのGVRAMページ番号\n";
      push @preparation, "int gx4th = CRTC.crtR12GrXCurr[pn];\n";
      push @preparation, "int gy4th = VideoController.vcnVisible4th + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);\n";
      push @preparation_half, "gx4th += half;\n";
      push @update1, "gx4th++;\n";
      push @update8, "gx4th += 8;\n";
    }
  }
  #512ドット256色
  if ($keyword =~ /F/) {
    if ($status->{'id_f1p'}) {
      push @preparation, "int pn = VideoController.vcnReg2Curr & 3;  //1番目のパレットのbit3-0のGVRAMページ番号\n";
      push @preparation, "int gx1st = CRTC.crtR12GrXCurr[pn];\n";
      push @preparation, "int gy1st = VideoController.vcnVisible1st + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);\n";
      push @preparation, "pn = VideoController.vcnReg2Curr >> 2 & 3;  //1番目のパレットのbit7-4のGVRAMページ番号\n";
      push @preparation, "int gx2nd = CRTC.crtR12GrXCurr[pn];\n";
      push @preparation, "int gy2nd = VideoController.vcnVisible2nd + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);\n";
      push @preparation_half, "gx1st += half;\n";
      push @preparation_half, "gx2nd += half;\n";
    }
    if ($status->{'id_f2p'} || $status->{'id_f2q'}) {
      push @preparation, "pn = VideoController.vcnReg2Curr >> 4 & 3;  //2番目のパレットのbit3-0のGVRAMページ番号\n";
      push @preparation, "int gx3rd = CRTC.crtR12GrXCurr[pn];\n";
      push @preparation_half, "gx3rd += half;\n";
    }
    if ($status->{'id_f2p'}) {
      push @preparation, "int gy3rd = VideoController.vcnVisible3rd + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);\n";
    }
    if ($status->{'id_f2q'}) {
      push @preparation, "int gz3rd = VideoController.vcnHidden3rd + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);\n";
    }
    if ($status->{'id_f2p'} || $status->{'id_f2q'}) {
      push @preparation, "pn = VideoController.vcnReg2Curr >> 6 & 3;  //2番目のパレットのbit7-4のGVRAMページ番号\n";
      push @preparation, "int gx4th = CRTC.crtR12GrXCurr[pn];\n";
      push @preparation_half, "gx4th += half;\n";
    }
    if ($status->{'id_f2p'}) {
      push @preparation, "int gy4th = VideoController.vcnVisible4th + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);\n";
    }
    if ($status->{'id_f2q'}) {
      push @preparation, "int gz4th = VideoController.vcnHidden4th + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);\n";
    }
    if ($status->{'id_f1p'}) {
      push @update1, "gx1st++;\n";
      push @update1, "gx2nd++;\n";
      push @update8, "gx1st += 8;\n";
      push @update8, "gx2nd += 8;\n";
    }
    if ($status->{'id_f2p'} || $status->{'id_f2q'}) {
      push @update1, "gx3rd++;\n";
      push @update1, "gx4th++;\n";
      push @update8, "gx3rd += 8;\n";
      push @update8, "gx4th += 8;\n";
    }
  }
  #512ドット65536色
  if ($keyword =~ /G/) {
    if ($status->{'id_g1p'}) {
      push @preparation, "int pn = VideoController.vcnReg2Curr & 3;  //1番目のパレットのbit3-0のGVRAMページ番号\n";
      push @preparation, "int gx1st = CRTC.crtR12GrXCurr[pn];\n";
      push @preparation, "int gy1st = (pn << 18) + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);\n";
      push @preparation, "pn = VideoController.vcnReg2Curr >> 2 & 3;  //1番目のパレットのbit7-4のGVRAMページ番号\n";
      push @preparation, "int gx2nd = CRTC.crtR12GrXCurr[pn];\n";
      push @preparation, "int gy2nd = (pn << 18) + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);\n";
      push @preparation, "pn = VideoController.vcnReg2Curr >> 4 & 3;  //1番目のパレットのbit11-8のGVRAMページ番号\n";
      push @preparation, "int gx3rd = CRTC.crtR12GrXCurr[pn];\n";
      push @preparation, "int gy3rd = (pn << 18) + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);\n";
      push @preparation, "pn = VideoController.vcnReg2Curr >> 6 & 3;  //1番目のパレットのbit15-12のGVRAMページ番号\n";
      push @preparation, "int gx4th = CRTC.crtR12GrXCurr[pn];\n";
      push @preparation, "int gy4th = (pn << 18) + ((CRTC.crtR13GrYZero[pn] + src & 511) << 9);\n";
      push @preparation_half, "gx1st += half;\n";
      push @preparation_half, "gx2nd += half;\n";
      push @preparation_half, "gx3rd += half;\n";
      push @preparation_half, "gx4th += half;\n";
      push @update1, "gx1st++;\n";
      push @update1, "gx2nd++;\n";
      push @update1, "gx3rd++;\n";
      push @update1, "gx4th++;\n";
      push @update8, "gx1st += 8;\n";
      push @update8, "gx2nd += 8;\n";
      push @update8, "gx3rd += 8;\n";
      push @update8, "gx4th += 8;\n";
    }
  }
  #1024ドット16色
  if ($keyword =~ /H/) {
  }
  #1024ドット256色
  if ($keyword =~ /I/) {
  }
  #1024ドット65536色
  if ($keyword =~ /J/) {
  }
  #構造
  push @body, "  $xkeyword {\n";
  push @body, "    \@Override public void drawRaster (int src, int dst, boolean rh) {\n";
  if ($keyword !~ /[Tt]/ && $keyword !~ /[HIJ]/) {  #テキストがなくて1024ドットもない
    push @body, map { "      $_" } @preparation;  #準備
    push @body, "      int da = dst << XEiJ.PNL_BM_OFFSET_BITS;  //ARGB出力インデックス\n";
    push @body, "      int db = da + XEiJ.pnlScreenWidth;  //ARGB出力インデックスの終了位置\n";
    push @body, "      if (rh) {\n";
    push @body, "        int half = XEiJ.pnlScreenWidth >> 4 << 3;\n";
    push @body, map { "        $_" } @preparation_half;  #準備half
    push @body, "        da += half;\n";
    push @body, "      }\n";
    push @body, "      while (da < db) {\n";
    push @body, map { "        $_" } @localvariable;  #ローカル変数宣言
    push @body, map { "        $_" } @{$draw[0]};
    push @body, map { "        $_" } @{$draw[1]};
    push @body, map { "        $_" } @{$draw[2]};
    push @body, map { "        $_" } @{$draw[3]};
    push @body, map { "        $_" } @{$draw[4]};
    push @body, map { "        $_" } @{$draw[5]};
    push @body, map { "        $_" } @{$draw[6]};
    push @body, map { "        $_" } @{$draw[7]};
    push @body, map { "        $_" } @update8;  #更新8
    push @body, "        da += 8;\n";
    push @body, "      }  //while da<db\n";
  } elsif ($keyword =~ /[Tt]/ && $keyword !~ /[HIJ]/) {  #テキストがあって1024ドットがない
    push @body, map { "      $_" } @preparation;  #準備
    push @body, "      int ty = CRTC.crtR11TxYZero + src & 1023;  //ラスタ\n";
    push @body, "      int tc = (ty & CRTC.crtMask3) << 7 | CRTC.crtR10TxXCurr >> 3;  //テキスト桁位置\n";
    push @body, "      int ta0 = 0x00e00000 + ((ty & CRTC.crtMaskMinus4) << 7);  //ラスタブロックアドレス\n";
    push @body, "      int ta1 = 0x00020000 + ta0;\n";
    push @body, "      int ta2 = 0x00040000 + ta0;\n";
    push @body, "      int ta3 = 0x00060000 + ta0;\n";
    push @body, "      int ts = CRTC.crtR10TxXCurr & 7;  //テキスト桁境界からのずれ\n";
    push @body, "      int da = dst << XEiJ.PNL_BM_OFFSET_BITS;  //ARGB出力インデックス\n";
    push @body, "      int db = da + XEiJ.pnlScreenWidth;  //ARGB出力インデックスの終了位置\n";
    push @body, "      if (rh) {\n";
    push @body, "        int half = XEiJ.pnlScreenWidth >> 4 << 3;\n";
    push @body, map { "        $_" } @preparation_half;  #準備half
    push @body, "        tc = tc + (half >> 3) & CRTC.crtMask511;\n";
    push @body, "        da += half;\n";
    push @body, "      }\n";
    push @body, "      if (ts == 0) {  //テキスト桁境界に合っているとき\n";
    push @body, "        while (da < db) {\n";
    push @body, "          int tp = (VideoController.VCN_TXP3[MainMemory.mmrM8[ta3 + tc] & 255] |\n";
    push @body, "                    VideoController.VCN_TXP2[MainMemory.mmrM8[ta2 + tc] & 255] |\n";
    push @body, "                    VideoController.VCN_TXP1[MainMemory.mmrM8[ta1 + tc] & 255] |\n";
    push @body, "                    VideoController.VCN_TXP0[MainMemory.mmrM8[ta0 + tc] & 255]);\n";
    push @body, "          tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置\n";
    push @body, map { "          $_" } @localvariable;  #ローカル変数宣言
    push @body, map { "          $_" } @{$draw[0]};
    push @body, map { "          $_" } @{$draw[1]};
    push @body, map { "          $_" } @{$draw[2]};
    push @body, map { "          $_" } @{$draw[3]};
    push @body, map { "          $_" } @{$draw[4]};
    push @body, map { "          $_" } @{$draw[5]};
    push @body, map { "          $_" } @{$draw[6]};
    push @body, map { "          $_" } @{$draw[7]};
    push @body, map { "          $_" } @update8;  #更新8
    push @body, "          da += 8;\n";
    push @body, "        }  //while da<db\n";
    push @body, "      } else {  //テキスト桁境界に合っていないとき\n";
    push @body, "        //                                                             ts=1のとき\n";
    push @body, "        int tt = ts + 8;                                             //tt=9\n";
    push @body, "        ts += 16;                                                    //ts=17\n";
    push @body, "        //                                                             ........ ........ ........ 01234567  m8[ta0+tc]\n";
    push @body, "        int p0 = MainMemory.mmrM8[ta0 + tc] << ts;                   //.......0 1234567_ ________ ________  p0=m8[ta0+tc]<<ts\n";
    push @body, "        int p1 = MainMemory.mmrM8[ta1 + tc] << ts;\n";
    push @body, "        int p2 = MainMemory.mmrM8[ta2 + tc] << ts;\n";
    push @body, "        int p3 = MainMemory.mmrM8[ta3 + tc] << ts;\n";
    push @body, "        tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置\n";
    push @body, "        while (da < db) {\n";
    push @body, "          //                                                           ........ ........ .1234567 ________  p0>>tt\n";
    push @body, "          //                                                           ........ ........ .1234567 89abcdef  p0>>tt|m8[ta0+tc]&255\n";
    push @body, "          p0 = (p0 >> tt | MainMemory.mmrM8[ta0 + tc] & 255) << ts;  //12345678 9abcdef_ ________ ________  p0=(p0>>tt|m8[ta0+tc]&255)<<ts\n";
    push @body, "          p1 = (p1 >> tt | MainMemory.mmrM8[ta1 + tc] & 255) << ts;  //~~~~~~~~\n";
    push @body, "          p2 = (p2 >> tt | MainMemory.mmrM8[ta2 + tc] & 255) << ts;  //ここを使う\n";
    push @body, "          p3 = (p3 >> tt | MainMemory.mmrM8[ta3 + tc] & 255) << ts;\n";
    push @body, "          int tp = (VideoController.VCN_TXP3[p3 >>> 24] |\n";
    push @body, "                    VideoController.VCN_TXP2[p2 >>> 24] |\n";
    push @body, "                    VideoController.VCN_TXP1[p1 >>> 24] |\n";
    push @body, "                    VideoController.VCN_TXP0[p0 >>> 24]);  //符号なし右シフトで&255を省略\n";
    push @body, "          tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置\n";
    push @body, map { "          $_" } @localvariable;  #ローカル変数宣言
    push @body, map { "          $_" } @{$draw[0]};
    push @body, map { "          $_" } @{$draw[1]};
    push @body, map { "          $_" } @{$draw[2]};
    push @body, map { "          $_" } @{$draw[3]};
    push @body, map { "          $_" } @{$draw[4]};
    push @body, map { "          $_" } @{$draw[5]};
    push @body, map { "          $_" } @{$draw[6]};
    push @body, map { "          $_" } @{$draw[7]};
    push @body, map { "          $_" } @update8;  #更新8
    push @body, "          da += 8;\n";
    push @body, "        }  //while da<db\n";
    push @body, "      }  //if ts==0\n";
  } elsif ($keyword !~ /[Tt]/ && $keyword =~ /[HIJ]/) {  #テキストがなくて1024ドットがある
    push @body, map { "      $_" } @preparation;  #準備
    push @body, "      int gx = CRTC.crtR12GrXCurr[0];  //1024ドットx座標。溢れは無視する\n";
    push @body, "      int gy = CRTC.crtR13GrYZero[0] + src;  //1024ドットy座標。溢れは無視する\n";
    if ($keyword =~ /H/) {
      push @body, "      int ga0 = ((gy & 511) << 9);  //x=0,y&=511の1024ドットアドレス\n";
    } elsif ($keyword =~ /I/) {
      push @body, "      int ga0 = ((gy & 511) << 9);  //x=0,y&=511の1024ドットアドレス\n";
    } elsif ($keyword =~ /J/) {
      push @body, "      int ga0 = ((gy & 511) << 9);  //x=0,y&=511の1024ドットアドレス\n";
    } else {
      die;
    }
    push @body, "      int gt = VideoController.vcnReg2Curr >> (gy >> 7 & 4);  //y<512?G2nd|G1st:G4th|G3rd\n";
    push @body, "      int da = dst << XEiJ.PNL_BM_OFFSET_BITS;  //ARGB出力インデックス\n";
    push @body, "      int db = da + XEiJ.pnlScreenWidth;  //ARGB出力インデックスの終了位置\n";
    push @body, "      if (rh) {\n";
    push @body, "        int half = XEiJ.pnlScreenWidth >> 4 << 3;\n";
    push @body, map { "        $_" } @preparation_half;  #準備half
    push @body, "        gx += half;\n";
    push @body, "        da += half;\n";
    push @body, "      }\n";
    push @body, "      int ga = ga0 + ((gt >> (gx >> 8 & 2) & 3) << 18) + (gx & 511);  //1024ドットアドレス\n";
    push @body, "      while (da < db) {\n";
    push @body, "        int dw = Math.min (db - da, (512 - (gx & 511)) & -8);  //今回の幅。8の倍数\n";
    push @body, "        gx += dw;  //次回の1024ドットx座標\n";
    push @body, "        int dc = da + dw;  //今回のARGB出力インデックスの終了位置\n";
    push @body, "        while (da < dc) {\n";
    push @body, map { "          $_" } @localvariable;  #ローカル変数宣言
    push @body, map { "          $_" } @{$draw[0]};
    push @body, map { "          $_" } @{$draw[1]};
    push @body, map { "          $_" } @{$draw[2]};
    push @body, map { "          $_" } @{$draw[3]};
    push @body, map { "          $_" } @{$draw[4]};
    push @body, map { "          $_" } @{$draw[5]};
    push @body, map { "          $_" } @{$draw[6]};
    push @body, map { "          $_" } @{$draw[7]};
    push @body, map { "          $_" } @update8;  #更新8
    push @body, "          ga += 8;\n";
    push @body, "          da += 8;\n";
    push @body, "        }  //while da<dc\n";
    push @body, "        if (da < db) {\n";
    push @body, "          for (int k = 0; k < 8; k++) {\n";
    push @body, "            if ((gx & 511) == 0) {  //gxが512の倍数のとき\n";
    push @body, "              ga = ga0 + ((gt >> (gx >> 8 & 2) & 3) << 18);  //gaを再計算する\n";
    push @body, "            }\n";
    push @body, "            gx++;\n";
    push @body, map { "            $_" } @localvariable;  #ローカル変数宣言
    push @body, map { "            $_" } @{$draw[0]};
    push @body, map { "            $_" } @update1;  #更新1
    push @body, "            ga++;\n";
    push @body, "            da++;\n";
    push @body, "          }  //for k\n";
    push @body, "        }  //if da<db\n";
    push @body, "      }  //while da<db\n";
  } elsif ($keyword =~ /[Tt]/ && $keyword =~ /[HIJ]/) {  #テキストがあって1024ドットもある
    push @body, map { "      $_" } @preparation;  #準備
    push @body, "      int ty = CRTC.crtR11TxYZero + src & 1023;  //ラスタ\n";
    push @body, "      int tc = (ty & CRTC.crtMask3) << 7 | CRTC.crtR10TxXCurr >> 3;  //テキスト桁位置\n";
    push @body, "      int ta0 = 0x00e00000 + ((ty & CRTC.crtMaskMinus4) << 7);  //ラスタブロックアドレス\n";
    push @body, "      int ta1 = 0x00020000 + ta0;\n";
    push @body, "      int ta2 = 0x00040000 + ta0;\n";
    push @body, "      int ta3 = 0x00060000 + ta0;\n";
    push @body, "      int ts = CRTC.crtR10TxXCurr & 7;  //テキスト桁境界からのずれ\n";
    push @body, "      int gx = CRTC.crtR12GrXCurr[0];  //1024ドットx座標。溢れは無視する\n";
    push @body, "      int gy = CRTC.crtR13GrYZero[0] + src;  //1024ドットy座標。溢れは無視する\n";
    if ($keyword =~ /H/) {
      push @body, "      int ga0 = ((gy & 511) << 9);  //x=0,y&=511の1024ドットアドレス\n";
    } elsif ($keyword =~ /I/) {
      push @body, "      int ga0 = ((gy & 511) << 9);  //x=0,y&=511の1024ドットアドレス\n";
    } elsif ($keyword =~ /J/) {
      push @body, "      int ga0 = ((gy & 511) << 9);  //x=0,y&=511の1024ドットアドレス\n";
    } else {
      die;
    }
    push @body, "      int gt = VideoController.vcnReg2Curr >> (gy >> 7 & 4);  //y<512?G2nd|G1st:G4th|G3rd\n";
    push @body, "      int da = dst << XEiJ.PNL_BM_OFFSET_BITS;  //ARGB出力インデックス\n";
    push @body, "      int db = da + XEiJ.pnlScreenWidth;  //ARGB出力インデックスの終了位置\n";
    push @body, "      if (rh) {\n";
    push @body, "        int half = XEiJ.pnlScreenWidth >> 4 << 3;\n";
    push @body, map { "        $_" } @preparation_half;  #準備half
    push @body, "        tc = tc + (half >> 3) & CRTC.crtMask511;\n";
    push @body, "        gx += half;\n";
    push @body, "        da += half;\n";
    push @body, "      }\n";
    push @body, "      int ga = ga0 + ((gt >> (gx >> 8 & 2) & 3) << 18) + (gx & 511);  //1024ドットアドレス\n";
    push @body, "      if (ts == 0) {  //テキスト桁境界に合っているとき\n";
    push @body, "        while (da < db) {\n";
    push @body, "          int dw = Math.min (db - da, (512 - (gx & 511)) & -8);  //今回の幅。8の倍数\n";
    push @body, "          gx += dw;  //次回の1024ドットx座標\n";
    push @body, "          int dc = da + dw;  //今回のARGB出力インデックスの終了位置\n";
    push @body, "          while (da < dc) {\n";
    push @body, "            int tp = (VideoController.VCN_TXP3[MainMemory.mmrM8[ta3 + tc] & 255] |\n";
    push @body, "                      VideoController.VCN_TXP2[MainMemory.mmrM8[ta2 + tc] & 255] |\n";
    push @body, "                      VideoController.VCN_TXP1[MainMemory.mmrM8[ta1 + tc] & 255] |\n";
    push @body, "                      VideoController.VCN_TXP0[MainMemory.mmrM8[ta0 + tc] & 255]);\n";
    push @body, "            tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置\n";
    push @body, map { "            $_" } @localvariable;  #ローカル変数宣言
    push @body, map { "            $_" } @{$draw[0]};
    push @body, map { "            $_" } @{$draw[1]};
    push @body, map { "            $_" } @{$draw[2]};
    push @body, map { "            $_" } @{$draw[3]};
    push @body, map { "            $_" } @{$draw[4]};
    push @body, map { "            $_" } @{$draw[5]};
    push @body, map { "            $_" } @{$draw[6]};
    push @body, map { "            $_" } @{$draw[7]};
    push @body, map { "            $_" } @update8;  #更新8
    push @body, "            ga += 8;\n";
    push @body, "            da += 8;\n";
    push @body, "          }  //while da<dc\n";
    push @body, "          if (da < db) {\n";
    push @body, "            int tp = (VideoController.VCN_TXP3[MainMemory.mmrM8[ta3 + tc] & 255] |\n";
    push @body, "                      VideoController.VCN_TXP2[MainMemory.mmrM8[ta2 + tc] & 255] |\n";
    push @body, "                      VideoController.VCN_TXP1[MainMemory.mmrM8[ta1 + tc] & 255] |\n";
    push @body, "                      VideoController.VCN_TXP0[MainMemory.mmrM8[ta0 + tc] & 255]);\n";
    push @body, "            tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置\n";
    push @body, "            for (int k = 0; k < 8; k++) {\n";
    push @body, "              if ((gx & 511) == 0) {  //gxが512の倍数のとき\n";
    push @body, "                ga = ga0 + ((gt >> (gx >> 8 & 2) & 3) << 18);  //gaを再計算する\n";
    push @body, "              }\n";
    push @body, "              gx++;\n";
    push @body, map { "              $_" } @localvariable;  #ローカル変数宣言
    push @body, map { "              $_" } @{$draw[0]};
    push @body, map { "              $_" } @update1;  #更新1
    push @body, "              tp <<= 4;\n";
    push @body, "              ga++;\n";
    push @body, "              da++;\n";
    push @body, "            }  //for k\n";
    push @body, "          }  //if da<db\n";
    push @body, "        }  //while da<db\n";
    push @body, "      } else {  //テキスト桁境界に合っていないとき\n";
    push @body, "        //                                                               ts=1のとき\n";
    push @body, "        int tt = ts + 8;                                               //tt=9\n";
    push @body, "        ts += 16;                                                      //ts=17\n";
    push @body, "        //                                                               ........ ........ ........ 01234567  m8[ta0+tc]\n";
    push @body, "        int p0 = MainMemory.mmrM8[ta0 + tc] << ts;                     //.......0 1234567_ ________ ________  p0=m8[ta0+tc]<<ts\n";
    push @body, "        int p1 = MainMemory.mmrM8[ta1 + tc] << ts;\n";
    push @body, "        int p2 = MainMemory.mmrM8[ta2 + tc] << ts;\n";
    push @body, "        int p3 = MainMemory.mmrM8[ta3 + tc] << ts;\n";
    push @body, "        tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置\n";
    push @body, "        while (da < db) {\n";
    push @body, "          int dw = Math.min (db - da, (512 - (gx & 511)) & -8);  //今回の幅。8の倍数\n";
    push @body, "          gx += dw;  //次回の1024ドットx座標\n";
    push @body, "          int dc = da + dw;  //今回のARGB出力インデックスの終了位置\n";
    push @body, "          while (da < dc) {\n";
    push @body, "            //                                                           ........ ........ .1234567 ________  p0>>tt\n";
    push @body, "            //                                                           ........ ........ .1234567 89abcdef  p0>>tt|m8[ta0+tc]&255\n";
    push @body, "            p0 = (p0 >> tt | MainMemory.mmrM8[ta0 + tc] & 255) << ts;  //12345678 9abcdef_ ________ ________  p0=(p0>>tt|m8[ta0+tc]&255)<<ts\n";
    push @body, "            p1 = (p1 >> tt | MainMemory.mmrM8[ta1 + tc] & 255) << ts;  //~~~~~~~~\n";
    push @body, "            p2 = (p2 >> tt | MainMemory.mmrM8[ta2 + tc] & 255) << ts;  //ここを使う\n";
    push @body, "            p3 = (p3 >> tt | MainMemory.mmrM8[ta3 + tc] & 255) << ts;\n";
    push @body, "            int tp = (VideoController.VCN_TXP3[p3 >>> 24] |\n";
    push @body, "                      VideoController.VCN_TXP2[p2 >>> 24] |\n";
    push @body, "                      VideoController.VCN_TXP1[p1 >>> 24] |\n";
    push @body, "                      VideoController.VCN_TXP0[p0 >>> 24]);  //符号なし右シフトで&255を省略\n";
    push @body, "            tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置\n";
    push @body, map { "            $_" } @localvariable;  #ローカル変数宣言
    push @body, map { "            $_" } @{$draw[0]};
    push @body, map { "            $_" } @{$draw[1]};
    push @body, map { "            $_" } @{$draw[2]};
    push @body, map { "            $_" } @{$draw[3]};
    push @body, map { "            $_" } @{$draw[4]};
    push @body, map { "            $_" } @{$draw[5]};
    push @body, map { "            $_" } @{$draw[6]};
    push @body, map { "            $_" } @{$draw[7]};
    push @body, map { "            $_" } @update8;  #更新8
    push @body, "            ga += 8;\n";
    push @body, "            da += 8;\n";
    push @body, "          }  //while da<dc\n";
    push @body, "          if (da < db) {\n";
    push @body, "            //                                                           ........ ........ .1234567 ________  p0>>tt\n";
    push @body, "            //                                                           ........ ........ .1234567 89abcdef  p0>>tt|m8[ta0+tc]&255\n";
    push @body, "            p0 = (p0 >> tt | MainMemory.mmrM8[ta0 + tc] & 255) << ts;  //12345678 9abcdef_ ________ ________  p0=(p0>>tt|m8[ta0+tc]&255)<<ts\n";
    push @body, "            p1 = (p1 >> tt | MainMemory.mmrM8[ta1 + tc] & 255) << ts;  //~~~~~~~~\n";
    push @body, "            p2 = (p2 >> tt | MainMemory.mmrM8[ta2 + tc] & 255) << ts;  //ここを使う\n";
    push @body, "            p3 = (p3 >> tt | MainMemory.mmrM8[ta3 + tc] & 255) << ts;\n";
    push @body, "            int tp = (VideoController.VCN_TXP3[p3 >>> 24] |\n";
    push @body, "                      VideoController.VCN_TXP2[p2 >>> 24] |\n";
    push @body, "                      VideoController.VCN_TXP1[p1 >>> 24] |\n";
    push @body, "                      VideoController.VCN_TXP0[p0 >>> 24]);  //符号なし右シフトで&255を省略\n";
    push @body, "            tc = tc + 1 & CRTC.crtMask511;  //次回のテキスト桁位置\n";
    push @body, "            for (int k = 0; k < 8; k++) {\n";
    push @body, "              if ((gx & 511) == 0) {  //gxが512の倍数のとき\n";
    push @body, "                ga = ga0 + ((gt >> (gx >> 8 & 2) & 3) << 18);  //gaを再計算する\n";
    push @body, "              }\n";
    push @body, "              gx++;\n";
    push @body, map { "              $_" } @localvariable;  #ローカル変数宣言
    push @body, map { "              $_" } @{$draw[0]};
    push @body, map { "              $_" } @update1;  #更新1
    push @body, "              tp <<= 4;\n";
    push @body, "              ga++;\n";
    push @body, "              da++;\n";
    push @body, "            }  //for k\n";
    push @body, "          }  //if da<db\n";
    push @body, "        }  //while da<db\n";
    push @body, "        ts -= 16;                                                      //ts=1\n";
    push @body, "      }  //if ts==0\n";
  } else {
    die;
  }
  push @body, "    }  //drawRaster\n";
  push @body, "  },  //$xkeyword\n";
  @body;
}  #sub generate



my $X_FROM_TO = {
  #                    .A.XHPGT          .A.XHPGT           .A.XHPGT
  ''    => { from => 0b00000000, to => 0b00001111, mask => '0000****' },
  XWC   => { from => 0b00010000, to => 0b00010011, mask => '000100**' },
  XWP   => { from => 0b00010100, to => 0b00010111, mask => '000101**' },
  XHC   => { from => 0b00011000, to => 0b00011000, mask => '00011000' },
  XHCT  => { from => 0b00011001, to => 0b00011001, mask => '00011001' },
  XHCG  => { from => 0b00011010, to => 0b00011010, mask => '00011010' },
  XHCGT => { from => 0b00011011, to => 0b00011011, mask => '00011011' },
  XHP   => { from => 0b00011100, to => 0b00011100, mask => '00011100' },
  XHPT  => { from => 0b00011101, to => 0b00011101, mask => '00011101' },
  XHPG  => { from => 0b00011110, to => 0b00011110, mask => '00011110' },
  XHPGT => { from => 0b00011111, to => 0b00011111, mask => '00011111' },
  A     => { from => 0b01000000, to => 0b01011111, mask => '010*****' }
  };

#================================================================================
#基本モードと拡張モードの組み合わせを作ってソースコードの全体を生成する
sub main {
  my @all_keyword_body = ();
  my @all_keyword_list = ();
  for (my $i = 0; $i <= $#KEYWORD; $i++) {
    my $keyword = $KEYWORD[$i];
    my $gonly = $keyword =~ /^(?:E1|E2|E3|E4|F1|F2|G|H|I|J)t?$/ ? $& : '';  #グラフィックのみ
    my $g1plus = $keyword =~ /(?:E1|E2|E3|E4|F1|F2|G|H|I|J)/ ? $& : '';  #グラフィックが1プレーン以上ある
    my $g2plus = $keyword =~ /(?:E1|E2|E3|E4|F1|F2)/ ? $& : '';  #グラフィックが2プレーン以上ある
    my @one_keyword_list = ();
    {
      my $xword = '';
      push @all_keyword_body, generate ($keyword, $xword);
      push @one_keyword_list, $keyword, $xword, $keyword, $xword;
    }
    my @ax_body = ();
    {
      my $xword = 'XWC';
      if ($gonly) {  #特殊プライオリティでグラフィックのみ。パレットは変わらないので無効
        push @one_keyword_list, $keyword, $xword, $keyword, '';  #拡張なしに変更
      } elsif ($g1plus) {  #特殊プライオリティでグラフィックとスプライトまたはテキストがある。グラフィックが手前でも奥に見えていたスプライトまたはテキストが見えなくなるので有効
        push @ax_body, generate ($keyword, $xword);
        push @one_keyword_list, $keyword, $xword, $keyword, $xword;
      } else {  #特殊プライオリティでグラフィックがない
        push @one_keyword_list, $keyword, $xword, $keyword, '';  #拡張なしに変更
      }
    }
    {
      my $xword = 'XWP';
      if ($g1plus) {  #特殊プライオリティでグラフィックがある。パレットが偶数化されるのでグラフィックのみでも有効
        push @ax_body, generate ($keyword, $xword);
        push @one_keyword_list, $keyword, $xword, $keyword, $xword;
      } else {  #特殊プライオリティでグラフィックがない
        push @one_keyword_list, $keyword, $xword, $keyword, '';  #拡張なしに変更
      }
    }
    {
      my $xword = 'XHC';
      #効果のない半透明
      push @one_keyword_list, $keyword, $xword, $keyword, '';  #拡張なしに変更
    }
    {
      my $xword = 'XHCT';
      if ($g1plus) {  #2番目を使わない半透明でグラフィックがある
        push @ax_body, generate ($keyword, $xword);
        push @one_keyword_list, $keyword, $xword, $keyword, $xword;
      } else {  #半透明でグラフィックがない
        push @one_keyword_list, $keyword, $xword, $keyword, '';  #拡張なしに変更
      }
    }
    {
      my $xword = 'XHCG';
      if ($g2plus) {  #2番目を使う半透明で2番目がある
        push @ax_body, generate ($keyword, $xword);
        push @one_keyword_list, $keyword, $xword, $keyword, $xword;
      } elsif ($g1plus) {  #2番目を使う半透明で1番目はあるが2番目がない
        #未対応
      } else {  #半透明でグラフィックがない
        push @one_keyword_list, $keyword, $xword, $keyword, '';  #拡張なしに変更
      }
    }
    {
      my $xword = 'XHCGT';
      if ($g2plus) {  #2番目を使う半透明で2番目がある
        push @ax_body, generate ($keyword, $xword);
        push @one_keyword_list, $keyword, $xword, $keyword, $xword;
      } elsif ($g1plus) {  #2番目を使う半透明で1番目はあるが2番目がない
        #未対応
      } else {  #半透明でグラフィックがない
        push @one_keyword_list, $keyword, $xword, $keyword, '';  #拡張なしに変更
      }
    }
    {
      my $xword = 'XHPT';
      if ($g1plus) {  #2番目を使わない半透明でグラフィックがある
        push @ax_body, generate ($keyword, $xword);
        push @one_keyword_list, $keyword, $xword, $keyword, $xword;
      } else {  #半透明でグラフィックがない
        push @one_keyword_list, $keyword, $xword, $keyword, '';  #拡張なしに変更
      }
    }
    {
      my $xword = 'XHPG';
      if ($g2plus) {  #2番目を使う半透明で2番目がある
        push @ax_body, generate ($keyword, $xword);
        push @one_keyword_list, $keyword, $xword, $keyword, $xword;
      } elsif ($g1plus) {  #2番目を使う半透明で1番目はあるが2番目がない
        #未対応
      } else {  #半透明でグラフィックがない
        push @one_keyword_list, $keyword, $xword, $keyword, '';  #拡張なしに変更
      }
    }
    {
      my $xword = 'XHPGT';
      if ($g2plus) {  #2番目を使う半透明で2番目がある
        push @ax_body, generate ($keyword, $xword);
        push @one_keyword_list, $keyword, $xword, $keyword, $xword;
      } elsif ($g1plus) {  #2番目を使う半透明で1番目はあるが2番目がない
        #未対応
      } else {  #半透明でグラフィックがない
        push @one_keyword_list, $keyword, $xword, $keyword, '';  #拡張なしに変更
      }
    }
    {
      my $xword = 'A';
      if ($gonly) {  #テキストパレット0と半透明でグラフィックのみ
        push @ax_body, generate ($keyword, $xword);
        push @one_keyword_list, $keyword, $xword, $keyword, $xword;
      } elsif ($g1plus) {  #テキストパレット0と半透明でグラフィックとスプライトまたはテキストがある
        push @one_keyword_list, $keyword, $xword, $g1plus, 'A';  #グラフィックのみに変更
      } else {  #テキストパレット0と半透明でグラフィックがない
        push @one_keyword_list, $keyword, $xword, 'N', '';  #表示なしに変更
      }
    }
    push @all_keyword_list, @one_keyword_list;
    shift @one_keyword_list;  #''
    shift @one_keyword_list;  #''
    shift @one_keyword_list;  #''
    shift @one_keyword_list;  #''
    my $text = join '＞', map { $KEY_TEXT{$_} } split /(?<=[0-9A-Za-z])(?![0-9])/, $keyword;
    push @all_keyword_body, "\n";
    push @all_keyword_body, "  //================================================================================\n";
    push @all_keyword_body, "  //X$keyword\n";
    push @all_keyword_body, "  //  概要\n";
    push @all_keyword_body, "  //    $keyword  $text\n";
    push @all_keyword_body, "  //    拡張あり\n";
    push @all_keyword_body, "  X$keyword {\n";
    push @all_keyword_body, "    \@Override public void drawRaster (int src, int dst, boolean rh) {\n";
    if (@one_keyword_list) {
      push @all_keyword_body, "      switch (VideoController.vcnReg3Curr >>> 8 & 0b01011111) {\n";
      while (@one_keyword_list) {
        shift @one_keyword_list;  #keyword
        my $xword = shift @one_keyword_list;
        my $keyword2 = shift @one_keyword_list;
        my $xword2 = shift @one_keyword_list;
        my $xkeyword = $xword eq '' ? $keyword : "${keyword}_$xword";
        my $xkeyword2 = $xword2 eq '' ? $keyword2 : "${keyword2}_$xword2";
        defined $X_FROM_TO->{$xword} or die $xword;
        my $from = $X_FROM_TO->{$xword}->{'from'};
        my $to = $X_FROM_TO->{$xword}->{'to'};
        push @all_keyword_body, "        //   .A.XHPGT\n";
        for (my $k = $from; $k <= $to; $k++) {
          push @all_keyword_body, sprintf "      case 0b%08b:  //$xkeyword\n", $k;
        }
        #push @all_keyword_body, "        //    $xword  $X_TEXT{$xword}\n";
        push @all_keyword_body, "        $xkeyword2.drawRaster (src, dst, rh);\n";
        push @all_keyword_body, "        break;\n";
      }
      push @all_keyword_body, "      default:\n";
      push @all_keyword_body, "        $keyword.drawRaster (src, dst, rh);\n";
      push @all_keyword_body, "        VideoController.vcnReportUnimplemented (X$keyword);\n";
      push @all_keyword_body, "      }  //switch\n";
    } else {
      push @all_keyword_body, "      $keyword.drawRaster (src, dst, rh);\n";
      push @all_keyword_body, "      VideoController.vcnReportUnimplemented (X$keyword);\n";
    }
    push @all_keyword_body, "    }  //drawRaster\n";
    push @all_keyword_body, "  },  //X$keyword\n";
    $i == $#KEYWORD and $ax_body[$#ax_body] =~ s/,/;/;
    push @all_keyword_body, @ax_body;
  }  #foreach keyword
  my @toc = ();
  for (my $n = 1; @all_keyword_list; $n++) {
    my $keyword = shift @all_keyword_list;
    my $xword = shift @all_keyword_list;
    my $keyword2 = shift @all_keyword_list;
    my $xword2 = shift @all_keyword_list;
    my $xkeyword = $xword eq '' ? $keyword : "${keyword}_$xword";
    my $xkeyword2 = $xword2 eq '' ? $keyword2 : "${keyword2}_$xword2";
    if ($xkeyword eq $xkeyword2) {
      push @toc, sprintf "  //    %4d. %s\n", $n, $xkeyword;
    } else {
      push @toc, sprintf "  //    %4d. %s → %s\n", $n, $xkeyword, $xkeyword2;
    }
  }
  my $toc = join '', @toc;
  my $all = join '', @all_keyword_body;
  my $fn = 'DrawingMode.java';
  open OUT, '>:encoding(utf8)', "$fn.tmp" or die;
  print OUT $JAVA_HEADER;
  print OUT "\n";
  print OUT "package xeij;\n";
  print OUT "\n";
  print OUT "public enum DrawingMode {\n";
  print OUT "\n";
  print OUT "  //================================================================================\n";
  print OUT "  //\n";
  print OUT "  //  表示できる画面モード\n";
  print OUT $toc;
  print OUT $all;
  print OUT "\n";
  print OUT "  public abstract void drawRaster (int src, int dst, boolean rh);\n";
  print OUT "\n";
  print OUT "}  //enum DrawingMode\n";
  print OUT "\n";
  print OUT "\n";
  print OUT "\n";
  close OUT;
  rename $fn, "$fn.bak";
  rename "$fn.tmp", $fn;
  print "$fn was updated\n";
}  #sub main

main ();



__END__




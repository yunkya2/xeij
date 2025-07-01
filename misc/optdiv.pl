#========================================================================================
#  optdiv.pl
#  Copyright (C) 2003-2019 Makoto Kamada
#
#  This file is part of the XEiJ (X68000 Emulator in Java).
#  You can use, modify and redistribute the XEiJ if the conditions are met.
#  Read the XEiJ License for more details.
#  https://stdkmd.net/xeij/
#========================================================================================

#----------------------------------------------------------------------------------------
#  除数が定数で被除数の範囲が限られている除算を逆数乗算に置き換える
#    賢いコンパイラならば被除数の範囲を正確に予測して自動的に変換してくれそうだがJavaはそこまでやってくれない
#    定理
#      0<y,0<=n,m=((1<<n)+y-1)/y,0<=x<=((((m-1)/(m*y-(1<<n))+1)<<n)-1)/mならばx/y==x*m>>>n
#    例
#      int xについて0<=x&&x<=99999999であることがわかっているときx/10000を(int)(x*109951163L>>>40)に置き換えると少し速くなる
#      perl optdiv.pl 99999999 10000
#        x/10000==x*109951163>>>40 (0<=x<=494389998) [99999999*109951163==10995116190048837]
#    x,y,mがすべてintでも2^32<=x_max*mのときはx*mをlongで行うこと
#----------------------------------------------------------------------------------------

use strict;  #厳密な文法に従う
use warnings;  #警告を表示する
use utf8;  #UTF-8で記述する

use GMP::Mpz qw(:all :constants);

{
  @ARGV == 2 or die "usage: perl optdiv.pl x_max y\n";
  my $x_max = mpz ($ARGV[0]);
  my $y = mpz ($ARGV[1]);
  for (my $n = 0; ; $n++) {
    my $m = ((1 << $n) + $y - 1) / $y;
    my $t = (((($m - 1) / ($m * $y - (1 << $n)) + 1) << $n) - 1) / $m;
    my $x_max_m = $x_max * $m;
    if ($x_max <= $t) {
      print "  x/$y==x*$m>>>$n (0<=x<=$t) [$x_max*$m==$x_max_m]\n";
      last;
    }
  }
}

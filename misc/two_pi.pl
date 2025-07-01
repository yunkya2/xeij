#========================================================================================
#  two_pi.pl
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

use GMP::Mpf qw(mpf);

sub pi {
  my ($one) = @_;
  my $a = $one;  #A=1
  my $b = sqrt ($one / 2);  #B=sqrt(1/2)
  my $t = $one / 4;  #T=1/4
  my $x = $one;  #X=1
  while ($a > $b) {  #while A>B
    my $y = $a;  #Y=A
    $a = ($a + $b) / 2;  #A=(A+B)/2
    $b = sqrt ($b * $y);  #B=sqrt(B*Y)
    $t -= $x * ($a - $y) ** 2;  #T=T-X*(A-Y)^2
    $x += $x;  #X=2*X
  }
  $a ** 2 / $t;  #A^2/T
}

{
  my $BITS = 31;
  my $UNIT = 1 << $BITS;
  my $NEED = 32768 + 400;
  my $COUNT = int (($NEED + $BITS - 1) / $BITS);
  my $COLS = 10;
  my $PREC = $NEED + 100;
  my $ONE = mpf (1, $PREC);
  my $TWO = mpf (2, $PREC);
  my $x = $TWO / pi ($ONE) / $TWO ** ($BITS * 3);  #2/pi/2^93
  for (my $i = 0; $i < $COUNT; $i++) {
    $i % $COLS == 0 and print '   ';
    $x *= $UNIT;
    my $t = int $x;
    printf ' 0x%08x,', $t;
    $x -= $t;
    $i % $COLS == $COLS - 1 and print "\n";
  }
}

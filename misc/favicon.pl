#========================================================================================
#  favicon.pl
#  Copyright (C) 2003-2019 Makoto Kamada
#
#  This file is part of the XEiJ (X68000 Emulator in Java).
#  You can use, modify and redistribute the XEiJ if the conditions are met.
#  Read the XEiJ License for more details.
#  https://stdkmd.net/xeij/
#========================================================================================

#----------------------------------------------------------------------------------------
#  XEiJのファビコンを作る
#----------------------------------------------------------------------------------------

use strict;  #厳密な文法に従う
use warnings;  #警告を表示する
use utf8;  #UTF-8で記述する
binmode STDOUT, ':encoding(cp932)';  #標準出力はcp932(Shift_JISでは'～'(\uff5e)が使えない)
binmode STDERR, ':encoding(cp932)';  #標準エラー出力はcp932(Shift_JISでは'～'(\uff5e)が使えない)

$| = 1;

sub floor {
  my ($x) = @_;
  my $y = int $x;
  $y <= $x ? $y : $y - 1;
}
sub ceil {
  my ($x) = @_;
  my $y = int $x;
  $y >= $x ? $y : $y + 1;
}
sub round {
  my ($x) = @_;
  floor ($x + 0.5);
}
sub trunc {
  my ($x) = @_;
  int $x;
}
sub signum {
  my ($x) = @_;
  $x < 0 ? -1 : $x > 0 ? 1 : 0;
}

my $w;
my $m;
sub init {
  my ($ww) = @_;
  $w = $ww;
  $m = [];
  for (my $y = 0; $y < $w; $y++) {
    $m->[$y] = [(0) x $w];
  }
}
sub pset {
  my ($x, $y) = @_;
  $x = round ($x);
  $y = round ($y);
  0 <= $x && $x < $w && 0 <= $y && $y < $w and $m->[$y]->[$x] = 1;
}
sub line {
  my @a = @_;
  while (@a >= 4) {
    my ($x0, $y0, $x1, $y1) = @a;
    @a = splice @a, 2;
    my $dx = $x1 - $x0;
    my $dy = $y1 - $y0;
    if (abs ($dx) <= abs ($dy)) {
      if ($dy < 0) {
        my $t = $x0;
        $x0 = $x1;
        $x1 = $t;
        $t = $y0;
        $y0 = $y1;
        $y1 = $t;
        $dx = -$dx;
        $dy = -$dy;
      }
      for (my $y = $y0; $y <= $y1; $y++) {
        pset ($x0 + $dx * ($y - $y0) / $dy, $y);
      }
    } else {
      if ($dx < 0) {
        my $t = $x0;
        $x0 = $x1;
        $x1 = $t;
        $t = $y0;
        $y0 = $y1;
        $y1 = $t;
        $dx = -$dx;
        $dy = -$dy;
      }
      for (my $x = $x0; $x <= $x1; $x++) {
        pset ($x, $y0 + $dy * ($x - $x0) / $dx);
      }
    }
  }
}
sub polygon {
  line (@_, @_[0 .. 1]);
}
sub resize {
  my ($ww) = @_;
  $w % $ww == 0 or die;
  my $scale = $w / $ww;
  my $mm = [];
  for (my $y = 0; $y < $ww; $y++) {
    $mm->[$y] = [(0) x $ww];
  }
  for (my $yy = 0; $yy < $ww; $yy++) {
    my $y = $scale * $yy;
    for (my $xx = 0; $xx < $ww; $xx++) {
      my $x = $scale * $xx;
      my $sum = 0;
      for (my $dy = 0; $dy < $scale; $dy++) {
        for (my $dx = 0; $dx < $scale; $dx++) {
          $sum += $m->[$y + $dy]->[$x + $dx];
        }
      }
      #$mm->[$yy]->[$xx] = $sum >= $scale * $scale / 2 ? 1 : 0;
      $mm->[$yy]->[$xx] = $sum / ($scale * $scale);
    }
  }
  $m = $mm;
  $w = $ww;
}
sub out {
  print "  public static final BufferedImage LNF_ICON_IMAGE_$w = XEiJ.createImage (\n";
  print "    $w, $w,\n";
  for (my $y = 0; $y < $w; $y++) {
    #print join ('', map { $_ >= 0.5 ? '■' : '□' } @{$m->[$y]}) . "\n";
    #print "    \"" . join ('', map { substr '0123456789ABCDEFF', floor ($_ * 16), 1 } @{$m->[$y]}) . ($y < $w - 1 ? "\" +" : "\",") . "\n";
    #print "    \"" . join ('', map { substr '011', floor ($_ * 2), 1 } @{$m->[$y]}) . ($y < $w - 1 ? "\" +" : "\",") . "\n";
    print "    \"" . join ('', map { substr '.11', floor ($_ * 2), 1 } @{$m->[$y]}) . ($y < $w - 1 ? "\" +" : "\",") . "\n";
  }
  #for (my $k = 0; $k <= 15; $k++) {
  for (my $k = 0; $k <= 15; $k += 15) {
    printf ("    0xff%06x%s\n", 0x111100 * $k, $k < 15 ? ',' : '');
  }
  print "    );\n";
}

{
  #my @sizes = (16, 32, 48, 152);
  my @sizes = (16, 32, 48);
  foreach my $size (@sizes) {
    init (1824);
    my $c = $w / 2 - 0.5;
    my $depth = $w / 16 - 1;
    for (my $d = 0; $d <= $depth; $d += 0.25) {
      polygon ($c + $c *  6.25 / 31.5 + $d * (1 - sqrt (5)) / 2, $c - $c * 27.5 / 31.5 + $d,
               $c + $c * 33.75 / 31.5 - $d * (1 + sqrt (5)) / 2, $c + $c * 27.5 / 31.5 - $d,
               $c - $c *  6.25 / 31.5 - $d * (1 - sqrt (5)) / 2, $c + $c * 27.5 / 31.5 - $d,
               $c - $c * 33.75 / 31.5 + $d * (1 + sqrt (5)) / 2, $c - $c * 27.5 / 31.5 + $d);
    }
    for (my $s = -1; $s <= 1; $s += 2) {
      for (my $d = 0; $d <= $depth; $d += 0.25) {
        polygon ($c + $s * ($c * 11.25 / 31.5 + $d * (1 + sqrt (5)) / 2),        $c - $s * ($c * 27.5 / 31.5 - $d),
                 $c + $s * ($c * 50.25 / 31.5 - $d * (1 + sqrt (2))),            $c - $s * ($c * 27.5 / 31.5 - $d),
                 $c + $s * ($c * 24.25 / 31.5 + $d * (sqrt (5) - sqrt (2)) / 3), $c - $s * ($c *  1.5 / 31.5 + $d * (2 * sqrt (2) + sqrt (5)) / 3));
      }
    }
    resize ($size);
    out ();
  }
  print "  public static final BufferedImage[] LNF_ICON_IMAGES = {\n";
  foreach my $size (@sizes) {
    print "    LNF_ICON_IMAGE_$size,\n";
  }
  print "  };\n";
}

__END__

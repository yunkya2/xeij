#========================================================================================
#  Graph.pm
#  Copyright (C) 2003-2019 Makoto Kamada
#
#  This file is part of the XEiJ (X68000 Emulator in Java).
#  You can use, modify and redistribute the XEiJ if the conditions are met.
#  Read the XEiJ License for more details.
#  https://stdkmd.net/xeij/
#========================================================================================

package Graph;

use strict;  #厳密な文法に従う
use warnings;  #警告を表示する
use utf8;  #UTF-8で記述する
#binmode STDOUT, ':encoding(cp932)';  #Shift_JISの代わりにcp932を使う
#binmode STDERR, ':encoding(cp932)';  #(Shift_JISでは'～'(\uff5e)が使えない)

use Math::Complex;  #Im

sub import {
  no strict 'refs';
  eval ('$' . __PACKAGE__ . '::OVERLOAD{""} = ""');
  *{__PACKAGE__ . '::()'} = sub {};
  *{__PACKAGE__ . '::(""'} = \&str;  #文字列化
  use strict 'refs';
}

#========================================================================

my $PI = 3.14159265358979323846264338328;

sub floor {
  my $x = int $_[0];
  $x <= $_[0] ? $x : $x - 1;
}

sub ceil {
  -floor (-$_[0]);
}

sub round {
  floor ($_[0] + 0.5);
}

sub rad {
  $_[0] * $PI / 180;
}

#========================================================================
sub new {
  my ($c, $w, $h, $l, $r, $b, $t) = @_;
  $w = round ($w // 80);
  $h = round ($h // 40);
  $r = $r // $w / 20;
  $l = $l // -$r;
  $t = $t // $h / 10;
  $b = $b // -$t;
  my $sx = $w / ($r - $l);
  my $sy = $h / ($b - $t);  #<0
  my $ox = (0 - $l) * $sx;
  my $oy = (0 - $t) * $sy;
  my $m = [];
  for (my $y = 0; $y <= $h; $y++) {
    push @$m, ' ' x ($w + 1);
  }
  bless {
    m => $m,
    w => $w,
    h => $h,
    l => $l,
    r => $r,
    b => $b,
    t => $t,
    ox => $ox,
    oy => $oy,
    sx => $sx,
    sy => $sy
  };
}

sub str {
  my ($g) = @_;
  join '', grep { $_ = "    //    $_\n"; } @{$g->{'m'}};
}

sub _pset {
  my ($g, $x, $y, $c) = @_;
  $x = round ($x);
  $y = round ($y);
  $c = $c // '*';
  $x >= 0 && $x <= $g->{'w'} && $y >= 0 && $y <= $g->{'h'} and vec ($g->{'m'}->[$y], $x, 8) = ord $c;
}

sub pset {
  my ($g, $x, $y, $c) = @_;
  $x = $g->{'ox'} + $g->{'sx'} * $x;
  $y = $g->{'oy'} + $g->{'sy'} * $y;
  $g->_pset ($x, $y, $c);
}

sub line {
  my ($g, $x1, $y1, $x2, $y2, $c) = @_;
  my $ox = $g->{'ox'};
  my $oy = $g->{'oy'};
  my $sx = $g->{'sx'};
  my $sy = $g->{'sy'};
  $x1 = $ox + $sx * $x1;
  $y1 = $oy + $sy * $y1;
  $x2 = $ox + $sx * $x2;
  $y2 = $oy + $sy * $y2;
  my $dx = $x2 - $x1;
  my $dy = $y2 - $y1;
  if ($dx == 0 && $dy == 0) {  #点
    $g->pset ($x1, $y1, $c);
  } elsif (abs ($dx) >= abs ($dy)) {  #横長
    my $i1 = round ($x1);
    my $i2 = round ($x2);
    if ($i1 <= $i2) {  #右向き
      if ($dy == 0) {  #水平線
        for (my $x = $i1; $x <= $i2; $x++) {
          $g->_pset ($x, $y1, $c);
        }
      } else {
        for (my $x = $i1; $x <= $i2; $x++) {
          my $y = $y1 + $dy * ($x - $x1) / $dx;
          $g->_pset ($x, $y, $c);
        }
      }
    } else {  #左向き
      if ($dy == 0) {  #水平線
        for (my $x = $i1; $x >= $i2; $x--) {
          $g->_pset ($x, $y1, $c);
        }
      } else {
        for (my $x = $i1; $x >= $i2; $x--) {
          my $y = $y1 + $dy * ($x - $x1) / $dx;
          $g->_pset ($x, $y, $c);
        }
      }
    }
  } else {  #縦長
    my $i1 = round ($y1);
    my $i2 = round ($y2);
    if ($i1 <= $i2) {  #下向き
      if ($dx == 0) {  #垂直線
        for (my $y = $i1; $y <= $i2; $y++) {
          $g->_pset ($x1, $y, $c);
        }
      } else {
        for (my $y = $i1; $y <= $i2; $y++) {
          my $x = $x1 + $dx * ($y - $y1) / $dy;
          $g->_pset ($x, $y, $c);
        }
      }
    } else {  #上向き
      if ($dx == 0) {  #垂直線
        for (my $y = $i1; $y >= $i2; $y--) {
          $g->_pset ($x1, $y, $c);
        }
      } else {
        for (my $y = $i1; $y >= $i2; $y--) {
          my $x = $x1 + $dx * ($y - $y1) / $dy;
          $g->_pset ($x, $y, $c);
        }
      }
    }
  }
}

sub circle {
  my ($g, $x, $y, $r, $c) = @_;
  for (my $i = 0; $i < 360; $i++) {
    my $s = rad ($i);
    my $t = rad ($i + 1);
    $g->line ($x + $r * cos $s, $y + $r * sin $s, $x + $r * cos $t, $y + $r * sin $t, $c);
  }
}

my $RESO = 1000;

#  a<=x<=bの範囲でy=f(x)を描く
sub func {
  my ($g, $f, $a, $b, $c) = @_;
  my $ox = $g->{'ox'};
  my $oy = $g->{'oy'};
  my $sx = $g->{'sx'};
  my $sy = $g->{'sy'};
  $a = $a // $g->{'l'};
  $b = $b // $g->{'r'};
  my $ia = round (($ox + $sx * $a) * $RESO);
  my $ib = round (($ox + $sx * $b) * $RESO);
  for (my $i = $ia; $i <= $ib; $i++) {
    my $x = $i / $RESO;
    my $y = undef;
    eval {
      $y = $f->(($x - $ox) / $sx);
    };
    defined ($y) && !Im ($y) and $g->_pset ($x, $oy + $sy * $y, $c);
  }
}

#  a<=t<=bの範囲でx=f(t),y=g(t)を描く
sub func2 {
  my ($G, $f, $g, $a, $b, $c) = @_;
  my $ox = $G->{'ox'};
  my $oy = $G->{'oy'};
  my $sx = $G->{'sx'};
  my $sy = $G->{'sy'};
  my $ia = round ($a * $RESO);
  my $ib = round ($b * $RESO);
  for (my $i = $ia; $i <= $ib; $i++) {
    my $t = $i / $RESO;
    my $x = undef;
    my $y = undef;
    eval {
      $x = $f->($t);
      $y = $g->($t);
    };
    defined ($x) && !Im ($x) && defined ($y) && !Im ($y) and $G->_pset ($ox + $sx * $x, $oy + $sy * $y, $c);
  }
}

sub grid {
  my ($g) = @_;
  my $l = $g->{'l'};
  my $r = $g->{'r'};
  my $b = $g->{'b'};
  my $t = $g->{'t'};
  my $ox = $g->{'ox'};
  my $oy = $g->{'oy'};
  my $sx = $g->{'sx'};
  my $sy = $g->{'sy'};
  for (my $x = ceil ($l / 4) * 4; $x <= $r; $x += 4) {
    $g->line ($x, $b, $x, $t, '|');
    for (my $y = ceil ($b); $y <= $t; $y++) {
      $g->pset ($x, $y, '+');
    }
  }
  for (my $y = ceil ($b / 4) * 4; $y <= $t; $y += 4) {
    $g->line ($l, $y, $r, $y, '-');
    for (my $x = ceil ($l); $x <= $r; $x++) {
      $g->pset ($x, $y, '+');
    }
  }
}

sub test {
  my $g = new Graph ();
  $g->line (5, 5, 35, 15);
  $g->circle (20, 10, 8);
  $g;
}

1;

__END__

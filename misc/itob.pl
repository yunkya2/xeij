#========================================================================================
#  itob.pl
#  Copyright (C) 2003-2022 Makoto Kamada
#
#  This file is part of the XEiJ (X68000 Emulator in Java).
#  You can use, modify and redistribute the XEiJ if the conditions are met.
#  Read the XEiJ License for more details.
#  https://stdkmd.net/xeij/
#========================================================================================

use strict;  #厳密な文法に従う
use warnings;  #警告を表示する
use utf8;  #UTF-8で記述する

{
  my ($fn, $id) = @ARGV;
  open IN, '<:encoding(utf8)', $fn or die "cannot open $fn";
  my $b = join '', map { s~//[^\n]*~~; $_ } <IN>;
  close IN;
  $b =~ / $id *= *{([^{}]*)}/ or die;
  my $s = $1;
  $s =~ s~\'(?:\\([\'\\])|([^\'\\]))\'~'(' . ord ($1 // $2).')'~eg;
  my %m = map { $_ => 0 } $s =~ /(?<!\w)[A-Z_a-z]\w*(?!\w)/g;
  foreach my $k (keys %m) {
    $b =~ / final +int +$k *= *([^;]+);/ or die $k;
    $m{$k} = eval $1;
  }
  $s =~ s/(?<!\w)[A-Z_a-z]\w*(?!\w)/$m{$&}/g;
  $s = join '', map {
    $_ = eval $_;
    0 <= $_ && $_ <= 255 or die;
    $_ == 8 ? '\\b' :
    $_ == 9 ? '\\t' :
    $_ == 10 ? '\\n' :
    $_ == 12 ? '\\f' :
    $_ == 13 ? '\\r' :
    $_ == 34 || $_ == 39 || $_ == 92 ? sprintf '\\%c', $_ :
    32 <= $_ && $_ <= 126 ? chr $_ :
    sprintf '\\%03o', $_;
  } $s =~ /([^,]+),/g;
  $s =~ s/(?<!\\)((?:\\\\)*\\)00([0-7])(?![0-7])/$1$2/g;
  $s =~ s/(?<!\\)((?:\\\\)*\\)0([0-7]{2})(?![0-7])/$1$2/g;
  printf "  public static final byte[] %s = \"%s\".getBytes (XEiJ.ISO_8859_1);\n", $id, $s;
}

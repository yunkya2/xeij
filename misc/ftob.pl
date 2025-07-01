#========================================================================================
#  ftob.pl
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
  my ($id, $fn) = @ARGV;  #識別子とファイル名
  #ファイルを読み込む
  open IN, '<', $fn or die "$fn not found";
  binmode IN;
  my $buffer;
  read IN, $buffer, (-s $fn);
  close IN;
  {
    my $str = join '', map {
      $_ == 8 ? '\\b' :
      $_ == 9 ? '\\t' :
      $_ == 10 ? '\\n' :
      $_ == 12 ? '\\f' :
      $_ == 13 ? '\\r' :
      $_ == 34 || $_ == 39 || $_ == 92 ? sprintf '\\%c', $_ :
      32 <= $_ && $_ <= 126 ? chr $_ :
      sprintf '\\%03o', $_;
    } unpack 'C*', $buffer;
    $str =~ s/(?<!\\)((?:\\\\)*\\)00([0-7])(?![0-7])/$1$2/g;
    $str =~ s/(?<!\\)((?:\\\\)*\\)0([0-7]{2})(?![0-7])/$1$2/g;
    printf "  public static final byte[] %s = \"%s\".getBytes (XEiJ.ISO_8859_1);\n", $id, $str;
  }
}

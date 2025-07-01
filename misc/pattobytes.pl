#========================================================================================
#  pattobytes.pl
#  Copyright (C) 2003-2021 Makoto Kamada
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
  my ($id, $fn) = @ARGV;  #識別子とパッチファイル名
  #パッチファイルを読み込む
  open IN, '<', $fn or die "$fn not found";
  binmode IN;
  my $head_buffer;  #X形式実行ファイルのヘッダ
  read IN, $head_buffer, 64;
  my $base_address = vec $head_buffer, 1, 32;  #挿入コードのベースアドレス
  my $text_size = vec $head_buffer, 3, 32;  #textセクション(追加コード)の長さ
  8 <= $text_size or die "text_size=$text_size";
  my $data_size = vec $head_buffer, 4, 32;  #dataセクション(挿入コード)の長さ
  4 <= $data_size or die "data_size=$data_size";
  my $text_buffer = '';  #textセクション(追加コード)
  read IN, $text_buffer, $text_size;
  my $data_buffer = '';  #dataセクション(挿入コード)
  read IN, $data_buffer, $data_size;
  close IN;
  #(追加コードの長さ)<=(追加コードの末尾アドレス+1-追加コードの先頭アドレス)を確認する
  my ($text_start, $text_end) = unpack 'N2', substr $data_buffer, 0, 8;  #先頭アドレス,末尾アドレス
  my $offset = $base_address - $text_start;
  if ($offset == 0) {
    printf "  //  text: \$%08X-\$%08X %d/%d %s\n",
    $text_start, $text_end,
    $text_size, $text_end + 1 - $text_start,
    $text_size <= $text_end + 1 - $text_start ? 'OK' : 'ERROR';
  } else {
    printf "  //  text: \$%08X-\$%08X \$%08X-\$%08X %d/%d %s\n",
    $text_start, $text_end,
    $text_start + $offset, $text_end + $offset,
    $text_size, $text_end + 1 - $text_start,
    $text_size <= $text_end + 1 - $text_start ? 'OK' : 'ERROR';
  }
  #(挿入コードの長さ)<=(挿入コードの末尾アドレス+1-挿入コードの先頭アドレス)を確認する
  my $pointer = 8;
  while (1) {
    my $start = unpack 'N', substr $data_buffer, $pointer, 4;  #先頭アドレス
    $start == 0 and last;
    my ($end, $original, $size) = unpack 'N3', substr $data_buffer, $pointer + 4, 12;  #末尾アドレス+1,元のデータ,長さ
    if ($offset == 0) {
      printf "  //  data: \$%08X-\$%08X %d/%d %s\n",
      $start, $end,
      $size, $end + 1 - $start,
      $size <= $end + 1 - $start ? 'OK' : 'ERROR';
    } else {
      printf "  //  data: \$%08X-\$%08X \$%08X-\$%08X %d/%d %s\n",
      $start, $end,
      $start + $offset, $end + $offset,
      $size, $end + 1 - $start,
      $size <= $end + 1 - $start ? 'OK' : 'ERROR';
    }
    $pointer += 16 + $size;
  }
  #Javaのコードを出力する
  foreach my $pair (['TEXT', $text_buffer], ['DATA', $data_buffer]) {
    length $pair->[1] or next;
    my $str = join '', map {
      $_ == 8 ? '\\b' :
      $_ == 9 ? '\\t' :
      $_ == 10 ? '\\n' :
      $_ == 12 ? '\\f' :
      $_ == 13 ? '\\r' :
      $_ == 34 || $_ == 39 || $_ == 92 ? sprintf '\\%c', $_ :
      32 <= $_ && $_ <= 126 ? chr $_ :
      sprintf '\\%03o', $_;
    } unpack 'C*', $pair->[1];
    $str =~ s/(?<!\\)((?:\\\\)*\\)00([0-7])(?![0-7])/$1$2/g;
    $str =~ s/(?<!\\)((?:\\\\)*\\)0([0-7]{2})(?![0-7])/$1$2/g;
    printf "  public static final byte[] %s_%s = \"%s\".getBytes (XEiJ.ISO_8859_1);\n", $id, $pair->[0], $str;
  }
}

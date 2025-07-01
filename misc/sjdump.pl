#========================================================================================
#  sjdump.pl
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

use Encode;

{
  my $file = undef;
  my $start = undef;
  my $end = undef;
  my $offset = undef;
  my $cols = undef;
  my $code = 0;
  my $zero = 0;
  my $sjis = 0;
  my $utf8 = 0;
  my $binary = 0;
  my $octal = 0;
  my $decimal = 0;
  my $hexadecimal = 0;
  my $usage = 0;
  for (my $i = 0; $i < @ARGV; $i++) {
    if ($ARGV[$i] eq '-code') {
      $code = 1;
    } elsif ($ARGV[$i] eq '-zero') {
      $zero = 1;
    } elsif ($ARGV[$i] eq '-ascii') {
      $sjis = 0;
      $utf8 = 0;
    } elsif ($ARGV[$i] eq '-sjis') {
      $sjis = 1;
      $utf8 = 0;
    } elsif ($ARGV[$i] eq '-utf8') {
      $sjis = 0;
      $utf8 = 1;
    } elsif ($ARGV[$i] eq '-bin') {
      $binary = 1;
    } elsif ($ARGV[$i] eq '-oct') {
      $octal = 1;
    } elsif ($ARGV[$i] eq '-dec') {
      $decimal = 1;
    } elsif ($ARGV[$i] eq '-hex') {
      $hexadecimal = 1;
    } elsif (!defined $file) {
      $file = $ARGV[$i];
    } elsif (!defined $start) {
      $start = $ARGV[$i];
    } elsif (!defined $end) {
      $end = $ARGV[$i];
    } elsif (!defined $offset) {
      $offset = eval ($ARGV[$i]) + 0;
    } elsif (!defined $cols) {
      $cols = eval ($ARGV[$i]) + 0;
    } else {
      $usage = 1;
    }
  }
  defined $file or $usage = 1;
  defined $start or $start = '+0';
  defined $end or $end = '-0';
  defined $offset or $offset = 0;
  defined $cols or $cols = ($binary ? 8 :
                            $octal ? 8 :
                            $decimal ? 16 :
                            16);
  $cols >= 1 or $usage = 1;
  $usage and die ("perl sjdump.pl <file> <start> <end> <offset> <cols> <option>\n" .
                  "  file   file name to be dumped\n" .
                  "  start  start position. n=n +n=n -n=eof-n [+0]\n" .
                  "  end    end position. n=n +n=start+n -n=eof-n [-0]\n" .
                  "  offset address of beginning of file\n" .
                  "  cols   bytes per line [16]\n" .
                  "  option\n" .
                  "    -code   generate a code to initialize an array\n" .
                  "    -zero   omit lines that consist of zeros\n" .
                  "    -ascii  character set is ASCII\n" .
                  "    -sjis   character set is SJIS\n");
  open IN, '<', $file or die "cannot open $file\n";
  binmode IN;
  seek IN, 0, 2;
  my $eof = tell IN;
  if ($start eq '-0') {
    $start = $eof;
  } else {
    $start = eval $start;
    $start < 0 and $start += $eof;
  }
  if ($end eq '-0') {
    $end = $eof;
  } elsif ($end =~ /^\+/) {
    $end = eval $end;
    $end += $start;
  } else {
    $end = eval $end;
    $end < 0 and $end += $eof;
  }
  $end >= 0 or $end = 0;
  $end <= $eof or $end = $eof;
  $start <= $end or $start = $end;
  my $start0 = int ($start / $cols) * $cols;
  $start -= $start0;
  $end -= $start0;
  seek IN, $start0, 0;
  my $data;
  my $readsize = read IN, $data, $end;
  close IN;
  $readsize == $end or die "cannot read $file\n";
  if (!$sjis && !$utf8) {
    if ($data =~ /^[\x00-\x7f]+$/) {  #ASCII
    } elsif ($data =~ /^(?:[\x00-\x7f\xa1-\xdf]|[\x81-\x9f\xe0-\xef][\x40-\x7e\x80-\xfc])+$/) {  #SJIS
      $sjis = 1;
    } elsif ($data =~ /^(?:[\x00-\x7f]|[\xc0-\xdf][\x80-\xbf]|[\xe0-\xef][\x80-\xbf][\x80-\xbf]|[\xf0-\xf7][\x80-\xbf][\x80-\xbf][\x80-\xbf])+$/) {  #UTF-8
      $utf8 = 1;
    }
  }
  my $format1 = $code ? '    ' : '%08x ';
  my $format2 = ($code ? '0x%02x,' :
                 $binary ? ' %08b' :
                 $octal ? ' %03o' :
                 $decimal ? ' %03d' :
                 ' %02x');
  my $format3 = ($code ? '     ' :
                 $binary ? '         ' :
                 $octal ? '    ' :
                 $decimal ? '    ' :
                 '   ');
  my $format4 = $code ? '  //%08x  ' : '  ';
  my $ignore = 0;  #1=直前の文字を2バイトで変換したので表示済み
  my $c = 0;  #最後に表示した文字
  for (my $i = int ($start / $cols) * $cols; $i < $end; $i += $cols) {
    if ($zero) {
      my $sum = 0;
      for (my $j = $i; $j < $i + $cols; $j++) {
        $start <= $j && $j < $end and $sum += vec $data, $j, 8;
      }
      $sum == 0 and next;
    }
    if ($format1 =~ /%/) {
      printf $format1, $start0 + $i;
    } else {
      print $format1;
    }
    for (my $j = $i; $j < $i + $cols; $j++) {
      if ($start <= $j && $j < $end) {
        printf $format2, vec $data, $j, 8;
      } else {
        print $format3;
      }
    }
    if ($format4 =~ /%/) {
      printf $format4, $offset + $start0 + $i;
    } else {
      print $format4;
    }
    for (my $j = $i; $j < $i + $cols; $j++) {
      if ($ignore) {  #表示済み
        $ignore--;
        next;
      }
      $c = $start <= $j && $j < $end ? vec $data, $j, 8 : 0x20;  #今回の文字。範囲外のときは空白にする
      $ignore = 0;
      if (0x20 <= $c && $c <= 0x7e) {  #今回の文字はASCII
      } elsif ($sjis && (0xa1 <= $c && $c <= 0xdf)) {  #今回の文字は半角カナ
        $c = ord Encode::decode ('cp932', pack 'C', $c);  #1バイトで変換する
      } elsif ($sjis && (0x81 <= $c && $c <= 0x9f || 0xe0 <= $c && $c <= 0xef)) {  #今回の文字はSJISの1バイト目
        my $d = $j + 1 < $end ? vec $data, $j + 1, 8 : 0;  #直後の文字
        if (0x40 <= $d && $d != 0x7f && $d <= 0xfc) {  #直後の文字はSJISの2バイト目
          $d = ord Encode::decode ('cp932', pack 'CC', $c, $d);  #2バイトで変換する
          if ($d != 0xfffd) {  #2バイトで変換できた
            $c = $d;
            $ignore = 1;
          } else {
            $c = 0x2e;
          }
        } else {
          $c = 0x2e;
        }
      } elsif ($utf8 && ($c & 0xe0) == 0xc0) {  #今回の文字は2バイトUTF-8の1バイト目
        my $d = $j + 1 < $end ? vec $data, $j + 1, 8 : 0;  #直後の文字
        if (($d & 0xc0) == 0x80) {  #直後の文字は2バイトUTF-8の2バイト目
          $c = ($c & 0x1f) << 6 | $d & 0x3f;
          $ignore = 1;
        } else {
          $c = 0x2e;
        }
      } elsif ($utf8 && ($c & 0xf0) == 0xe0) {  #今回の文字は3バイトUTF-8の1バイト目
        my $d = $j + 1 < $end ? vec $data, $j + 1, 8 : 0;  #直後の文字
        my $e = $j + 2 < $end ? vec $data, $j + 2, 8 : 0;  #直後の直後の文字
        if (($d & 0xc0) == 0x80 &&  #直後の文字は3バイトUTF-8の2バイト目
            ($e & 0xc0) == 0x80) {  #直後の直後の文字は3バイトUTF-8の3バイト目
          $c = ($c & 0x0f) << 12 | ($d & 0x3f) << 6 | $e & 0x3f;
          $ignore = 2;
        } else {
          $c = 0x2e;
        }
      } elsif ($utf8 && ($c & 0xf8) == 0xf0) {  #今回の文字は4バイトUTF-8の1バイト目
        my $d = $j + 1 < $end ? vec $data, $j + 1, 8 : 0;  #直後の文字
        my $e = $j + 2 < $end ? vec $data, $j + 2, 8 : 0;  #直後の直後の文字
        my $f = $j + 3 < $end ? vec $data, $j + 3, 8 : 0;  #直後の直後の直後の文字
        if (($d & 0xc0) == 0x80 &&  #直後の文字は4バイトUTF-8の2バイト目
            ($e & 0xc0) == 0x80 &&  #直後の直後の文字は4バイトUTF-8の3バイト目
            ($f & 0xc0) == 0x80) {  #直後の直後の直後の文字は4バイトUTF-8の4バイト目
          $c = ($c & 0x07) << 18 | ($d & 0x3f) << 12 | ($e & 0x3f) << 6 | $f & 0x3f;
          $ignore = 3;
        } else {
          $c = 0x2e;
        }
      } else {  #その他
        $c = 0x2e;
      }
      print chr $c;
    }
    $c == 0x5c and print '.';  #行末に\があるとき.を付けておく
    print "\n";
  }
}

1;

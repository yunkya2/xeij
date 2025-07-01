#========================================================================================
#  itoc.pl
#  Copyright (C) 2003-2019 Makoto Kamada
#
#  This file is part of the XEiJ (X68000 Emulator in Java).
#  You can use, modify and redistribute the XEiJ if the conditions are met.
#  Read the XEiJ License for more details.
#  https://stdkmd.net/xeij/
#========================================================================================

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
    $_ = eval $_; 0 <= $_ && $_ <= 65535 or die;
    $_ == 8 ? '\\b' : $_ == 9 ? '\\t' : $_ == 10 ? '\\n' : $_ == 12 ? '\\f' : $_ == 13 ? '\\r' :
    $_ == 34 || $_ == 39 || $_ == 92 ? sprintf '\\%c', $_ : 32 <= $_ && $_ <= 126 ? chr $_ :
    $_ <= 255 ? sprintf '\\%03o', $_ : sprintf '\\u%04x', $_;
  } $s =~ /([^,]+),/g;
  $s =~ s/(?<!\\)((?:\\\\)*\\)00([0-7])(?![0-7])/$1$2/g;
  $s =~ s/(?<!\\)((?:\\\\)*\\)0([0-7]{2})(?![0-7])/$1$2/g;
  $s =~ s/(?<!\\)((?:\\\\)*\\)([0-3][0-7]{2})(?![0-7])/$1 . sprintf 'x%02x', oct $2/eg;
  printf "  public static final char[] %s = \"%s\".toCharArray ();\n", $id, $s;
}

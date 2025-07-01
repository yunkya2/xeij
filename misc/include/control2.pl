#--------------------------------------------------------------------------------
#  control2.pl
#    control.macからcontrol2.macへの変換
#--------------------------------------------------------------------------------
#  include
#    変換前 <path>control.mac
#    変換後 <path>control2.mac
#  break/continue/elif/if/next/redo/while
#    変換前 cc,<op1>,…,<opN>
#    変換後 <op1>,…,<opN>,cc
#  goto
#    変換前 label,cc,<op1>,…,<opN>
#    変換後 <op1>,…,<opN>,cc,label
#  breakand/breakor/continueand/continueor/elifand/elifor/ifand/ifor/redoand/redoor/whileand/whileor
#    変換前 cc1,<op1>,…,ccN[,<opN>]
#    変換後 <op1>,cc1,…,<opN>,ccN
#    (opNが省略されたとき<>を補う)
#  gotoand/gotoor
#    変換前 label,cc1,<op1>,…,ccN[,<opN>]
#    変換後 <op1>,cc1,…,<opN>,ccN,label
#    (opNが省略されたとき<>を補う)
#--------------------------------------------------------------------------------

use strict;
use utf8;
use warnings;

my $OP = "(?:<(?:[^>\\']|\\'[^\\']*\\')*>)";
my $CC = "(?:\\b(?:f|t|hi|ls|cc|hs|cs|lo|ne|nz|eq|ze|vc|vs|pl|mi|ge|lt|gt|le)\\b)";
my $LABEL = "(?:[0-9\\\@A-Z_a-z~]*)";

my $INCLUDE = "(?<include>(?<macro>\\.?\\binclude)(?<space>\\s+)(?<param>(?:[A-Za-z]\\:)?(?:[0-9A-Z_a-z]*[\\/\\\\])*control\\.mac\\b))";
my $BREAK = "(?<break>\\b(?<macro>break|continue|elif|if|next|redo|while)(?<space>\\s+)(?<param>$CC(?:,$OP)*))";
my $GOTO = "(?<goto>\\b(?<macro>goto)(?<space>\\s+)(?<param>$LABEL(?:,$CC(?:,$OP)*)?))";
my $BREAKAND = "(?<breakand>\\b(?<macro>breakand|breakor|continueand|continueor|elifand|elifor|ifand|ifor|redoand|redoor|whileand|whileor)(?<space>\\s+)(?<param>$CC(?:,$OP,$CC)*(?:,$OP)?))";
my $GOTOAND = "(?<gotoand>\\b(?<macro>gotoand|gotoor)(?<space>\\s+)(?<param>$LABEL(?:,$CC(?:,$OP,$CC)*(?:,$OP)?)?))";

{
  my $encoding = 'cp932';
  my @input_names = ();
  my $output_name = '-';
  my @a = @ARGV;
  while (@a) {
    my $a = shift @a;
    if ($a eq '-e') {
      $encoding = shift @a;
    } elsif ($a eq '-o') {
      $output_name = shift @a;
    } else {
      push @input_names, $a;
    }
  }
  @input_names or die "usage: perl control2.pl -e encoding -o output-name input-name ...\n";
  my @s = ();
  foreach my $input_name (@input_names) {
    my $s;
    if ($input_name eq '' ||
        $input_name eq '-') {
      binmode STDIN, ":encoding($encoding)";
      $s = join '', <STDIN>;
    } else {
      open IN, "<:encoding($encoding)", $input_name or die "$input_name not found\n";
      $s = join '', <IN>;
      close IN;
    }
    while ($s =~ /(?:$INCLUDE|$BREAK|$GOTO|$BREAKAND|$GOTOAND)/) {
      #print "\t$&\n";
      push @s, $`;
      $s = $';
      my $macro = $+{'macro'};
      my $space = $+{'space'};
      my $param = $+{'param'};
      push @s, $macro, $space;
      if (defined $+{'include'}) {
        $param =~ /\bcontrol\.mac$/ or die;
        push @s, $`, 'control2.mac';
      } elsif (defined $+{'break'}) {
        $param =~ /^($CC)/ or die;
        $param = $';
        my $cc = $1;
        my @t = ();
        while ($param =~ /^,($OP)/) {
          $param = $';
          push @t, $1;
        }
        $param eq '' or die;
        push @s, join ',', @t, $cc;
      } elsif (defined $+{'goto'}) {
        $param =~ /^($LABEL)/ or die;
        $param = $';
        my $label = $1;
        my @t = ();
        if ($param =~ /^,($CC)/) {
          $param = $';
          my $cc = $1;
          while ($param =~ /^,($OP)/) {
            $param = $';
            push @t, $1;
          }
          push @t, $cc;
        }
        $param eq '' or die;
        push @s, join ',', @t, $label;
      } elsif (defined $+{'breakand'}) {
        $param =~ /^($CC)/ or die;
        $param = $';
        my $cc = $1;
        my @t = ();
        while ($param =~ /^,($OP),($CC)/) {
          $param = $';
          push @t, $1, $cc;
          $cc = $2;
        }
        if ($param =~ /^,($OP)/) {
          $param = $';
          push @t, $1, $cc;
        } else {
          push @t, '<>', $cc;
        }
        $param eq '' or die;
        push @s, join ',', @t;
      } elsif (defined $+{'gotoand'}) {
        $param =~ /^($LABEL)/ or die;
        $param = $';
        my $label = $1;
        my @t = ();
        while ($param =~ /^,($CC),($OP)/) {
          $param = $';
          push @t, $2, $1;
        }
        if ($param =~ /^,($CC)/) {
          $param = $';
          push @t, '<>', $1;
        }
        $param eq '' or die;
        push @s, join ',', @t, $label;
      }
    }
    push @s, $s;
  }
  my $s = join '', @s;
  if ($output_name eq '' ||
      $output_name eq '-') {
    binmode STDOUT, ":encoding($encoding)";
    print STDOUT $s;
  } else {
    my $tmp_name = "$output_name.tmp~";
    my $bak_name = "$output_name.bak~";
    open OUT, ">:encoding($encoding)", $tmp_name or die "$tmp_name not created\n";
    print OUT $s;
    close OUT;
    rename $output_name, $bak_name;
    rename $tmp_name, $output_name;
    chmod 0644, $output_name;
    print "$output_name created\n";
  }
}

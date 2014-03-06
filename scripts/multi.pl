#!/usr/bin/env perl

use strict;
use warnings;

my $flag = "%"; #  '#' doesn't work for bash

my ($match, @posRegex, @negRegex);
# Option parcing
while (@ARGV && $ARGV[0] =~ /^-/) {
   (my $arg = shift) =~ s/^-+//;
   help() if ($arg =~ /^h/i);
   if ($arg =~ /^match/i) {
      $match = shift;
      next;
   }
   if ($arg =~ /^pos/i) {
      my $reg = shift || "";
      my $num = shift || 0;
      $num =~ s/\D//g;
      if ($num > 0) {
         push @posRegex, "$num:$reg";
      } else {
         die "-pos must be followed by 'regex index'\n";
      }
      next;
   }
   if ($arg =~ /^neg/i) {
      my $reg = shift || "";
      my $num = shift || 0;
      $num =~ s/\D//g;
      if ($num > 0) {
         push @negRegex, "$num:$reg";
      } else {
         die "-pos must be followed by 'regex' and 'index'\n";
      }
      next;
   }
   die "I don't understand '-$arg'.  Aborting.\n";
}

help() unless (@ARGV);

my $command = "@ARGV";
my $found = "";
foreach (@ARGV) {
   if (/$flag/) {
      $found = "true";
      $match = $_ unless $match;
      last;
   }
}

if (! $found || $match !~ /$flag/) {
	die "you need to use $flag somewhere\n";
}

my $count = (my $search = $match) =~ s/$flag/\*/g;
(my $regex = $match) =~ s/$flag/\(.*\)/g;
my @list = glob ($search);

my @matches;
foreach my $name (@list) {
   @matches = ();
   if ($name =~ $regex) {
      my $num = @- - 1;
      if ($num != $count) {
         warn "Regex matching problem with $name ($num != $count).  Skipping.\n";
         next;
      }
      # make an array of the matches
      for my $loop (1..$num) {
         push @matches, substr($name, $-[$loop], $+[$loop] - $-[$loop])
      }
      # check all positive and negative regexs
      my $problem = "";
      foreach my $pos (@posRegex) {
         my ($reg, $num);
         if ($pos =~ /^(\d+):(.+)$/) {
            $reg = $2;
            $num = $1;
         } else {
            warn "huh $pos\n";
            next;
         }
         if ($num > $count) {
            die "You ask for match '$num', but there are only $count matches\n";
         } # if num > count
         if ($matches[$num - 1] !~ /$reg/) {
            $problem = "true";
            last;
         } # if doesnt' match
      } # foreach pos
      foreach my $neg (@negRegex) {
         my ($reg, $num);
         if ($neg =~ /^(\d+):(.+)$/) {
            $reg = $2;
            $num = $1;
         } else {
            warn "huh $neg\n";
            next;
         }
         if ($num > $count) {
            die "You ask for match '$num', but there are only $count matches\n";
         } # if num > count
         if ($matches[$num - 1] =~ /$reg/) {
            $problem = "true";
            last;
         } # if doesnt' match
      } # foreach neg
      next if ($problem);
      (my $newcmd = $command) =~ s/($flag+)/completeMatch($1)/ge;
      print "unix> $newcmd\n";
      print `$newcmd`."\n";
   } else {
      warn "WARNING: help $name\n";
   }
}

sub completeMatch {
   my $howmany = shift;
   my $index = length ($howmany) - 1;
   die "Don't have that many matches '$howmany'\n" if ($index >= @matches);
   return $matches[$index];
}

sub help {
   (my $script = $0) =~ s|.+/||g;
   die "Usage: $script [-args] command oldname$flag newname$flag
ex:
$script mv $flag.txt $flag.txt.old
options:
--help          => This screen
--match XX\%YY   => Glob 'XX*YY'
--neg reg 1     => require that the nth (1) glob does NOT matches 'reg'
--pos reg 1     => require that the nth (1) glob matches 'reg'
\n";
}

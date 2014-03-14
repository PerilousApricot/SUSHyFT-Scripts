#!/usr/bin/env perl

use warnings;
use strict;

my $cc          = "cc";
my $defaultfile = ".selectCCfiles.default";

# Option parcing
my ($exe, $src, $main);
my $verbose = "true";
while (@ARGV && $ARGV[0] =~ /^-/) {
   (my $arg = shift) =~ s/^-+//;
   help() if ($arg =~ /^h/i);
   if ($arg =~ /^exe/i) {
      $exe = "true";
      $verbose = "";
      next;
   }
   if ($arg =~ /^main/i) {
      $main = "true";
      $verbose = "";
      next;
   }
   if ($arg =~ /^src/i) {
      $src = "true";
      next;
   }
   die "I don't understand '-$arg'.  Aborting.\n";
}

my $base = shift || "";
if (! $base) {
   if (-e $defaultfile) {
      if (open (TARGET, "<", $defaultfile)) {
         while (<TARGET>) {
            chomp;
            $base = $_;
            last;
         }
         close TARGET;
         #print "base $base:\n";
      }
   } else {
      chomp (my $pwd = `pwd`);
      ($base = $pwd) =~ s|.+/||g;
      #print "base $base\n";
   }
}

$base =~ s/\.exe$//;
$base =~ s/\.$//;
$base =~ s/\.$cc$//;
die "Usage: $0 bla.cc\n" unless ($base);

my @files = glob ("$base*.$cc");
#print "$base*.$cc : files @files\n";

if (1 != @files) {
   die "Can only give one $cc file (@files)\n" if $verbose;
   exit(1);
}

my $mainsrc = shift @files;

if ($exe) {
   ($exe = $mainsrc) =~ s/\.$cc$/.exe/;
   print "$exe\n";
   exit;
}

if ($main) {
   ($main = $mainsrc) =~ s/\.$cc$//;
   print "$main\n";
   exit;
}

if ($src) {
   my @srcfiles = glob ("*.$cc");
   my @goodfiles;
   foreach my $file (@srcfiles) {
      next if ($file eq $mainsrc);
      open (SOURCE, "<", $file) or next;
      my $ok = "true";
      while (<SOURCE>) {
         if (/int\s+main\s*\(/) {
            $ok = "";
            last;
         } # if int main
         if (/void\s+main\s*\(/) {
            $ok = "";
            last;
         } # if int main         
      } # while source
      push @goodfiles, $file if ($ok);
   }
   push @goodfiles, $mainsrc;
   print "@goodfiles\n";
}

sub help {
   (my $name = $0) =~ s|.+/||g;
   die "Usage: $name [-options] [bla.cc]
--exe   => print out executable name (e.g., bla.exe)
--help  => print out this help screen
--main  => print out main name (e.g., bla)
--src   => print out all source files

If no src file is given, $name will first check to see if
'$defaultfile' exists and has the name of a default source file.
If not, it will use the name of the current directory.
";
}

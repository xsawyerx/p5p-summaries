#!/usr/bin/perl
# This script helps expand common expressions when writing a summary.
#
# To enable add the following (or the likes) in your .vimrc:
# map <F2> :!perl /path/to/p5p-summaries/bin/expand.pl<CR>
# (Change F2 as you wish.)
#
# To run mark a line (or lines) using ctrl+v and press F2.
#
# What it does:
# * Replace RT#NUMBER with proper rt.perl.org Markdown link
# * Replace ML:description#NUMBER with proper NNTP Markdown link
# * Replace MC#MODULE with proper Metacpan.org Markdown link

use strict;
use warnings;

my %REGEX = (
    RT => qr/RT#(\d+)/,
    ML => qr/ML:([A-Za-z\s0-9]+)#(\d+)/,
    MC => qr/MC#([A-Za-z\:\_0-9]+)/,
);

while ( my $line = <STDIN> ) {
    $line =~ s!$REGEX{'RT'}![Perl #$1](https://rt.perl.org/Ticket/Display.html?id=$1)!g;
    $line =~ s!$REGEX{'ML'}![$1](http://www.nntp.perl.org/group/perl.perl5.porters/$2)!g;
    $line =~ s!$REGEX{'MC'}![$1](https://metacpan.org/pod/$1)!g;
    print $line;
}

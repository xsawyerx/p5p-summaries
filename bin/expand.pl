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
use HTTP::Tiny;
use Web::Query qw< wq >;
use Text::Wrap qw< wrap >;
use Path::Tiny qw< path >;

local $ENV{'HTTP_PROXY'}   = '';
local $ENV{'http_proxy'}   = '';
local $ENV{'https_proxy'}  = '';
local $Text::Wrap::columns = 72;

my $ua = HTTP::Tiny->new(
    'proxy'       => undef,
    'http_proxy'  => undef,
    'https_proxy' => undef,
);

my %REGEX = (
    'RT' => qr/RT\#(\d+)/xms,
    'ML' => qr/ML:([A-Za-z\s0-9]+)\#(\d+)/xms,
    'MC' => qr/MC\#([A-Za-z\:\_0-9]+)/xms,
);

my $log = path('/tmp/summaries.txt');

sub escape_markdown {
    $_[0] =~ s@([\\`\*\{\}\[\]\(\)\#\+\-\.\!\_\>])@\\$1@xmsg;
    return;
}

while ( my $line = <STDIN> ) {
    my $match;
    my $spaces = '';

    #if ( $line =~ m{^([^A-Z]+)}xms ) {
    if ( $line =~ m{^([\s\*\-]+)}xms ) {
        $spaces = ' ' x length $1;
    }

    while ( $line =~ $REGEX{'RT'} ) {
        $match = 1;
        my $ticket_id = $1;

        $log->append("[Perl #$ticket_id] Fetching details...\n");

        my $url     = "http://rt.perl.org/Ticket/Display.html?id=$ticket_id";
        my $content = $ua->get($url)->{'content'};
        my $title   = wq($content)->find('title')->first->text;
        $title =~ s{^Bug \s \#$ticket_id \s for \s perl5: \s*}{}xms;
        $log->append("[Perl #$ticket_id] Found title: $title.\n");
        escape_markdown($title);

        $line =~ s!$REGEX{'RT'}![Perl #$ticket_id]($url): $title.!xms;
        $line = wrap( '', $spaces, $line );
    }

    while ( $line =~ $REGEX{'ML'} ) {
        $match = 1;

        my $ml_text = $1;
        my $ml_id   = $2;

        $log->append("[NNTP #$ml_id] Fetching details...\n");

        my $url = "http://www.nntp.perl.org/group/perl.perl5.porters/$ml_id";
        my $content = $ua->get($url)->{'content'};
        my $title   = wq($content)->find('title')->first->text;
        $title =~ s{ \s+ - \s+ nntp\.perl\.org \s* $}{}xms;
        $log->append("[NNTP #$ml_id] Found title: $title.\n");
        escape_markdown($title);

        $line =~ s!$REGEX{'ML'}![$1]($url) ($title)!xms;
        $line = wrap( '', $spaces, $line );
    }

    while ( $line =~ $REGEX{'MC'} ) {
        $match = 1;
        my $module_name = $1;

        $log->append("[CPAN: $module_name] Creating URL.\n");

        my $url = "http://metacpan.org/pod/$module_name";

        $line =~ s!$REGEX{'MC'}![$1]($url)!xms;
        $line = wrap( '', '', $line );
    }

    $match
        or $line = wrap( '', $spaces, $line );

    print $line;
}

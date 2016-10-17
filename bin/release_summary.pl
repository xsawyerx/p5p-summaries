#!/usr/bin/perl
use strict;
use warnings;
use Path::Tiny       qw< path   >;
use IO::Prompt::Tiny qw< prompt >;
use Web::Query;
use Term::ANSIColor;

$|++;

my $textify = path( 'bin', 'textify' );

my $filename = $ARGV[0]
    or die "<$0> file.md\n";

my $mdfile = path($filename);

$mdfile->exists
    or die "$mdfile doesn't exist\n";

$textify->exists
    or die "$textify doesn't exist\n";

my $txtfile = path( $mdfile->basename =~ s{\.md$}{.txt}r );

if ( $txtfile->exists ) {
    print "Sorry, $txtfile already exists!\n";
    my $answer = prompt( 'Remove it? (y/n)', 'y' );
    $answer ne 'y' and die "Then we're out.\n";
    $txtfile->remove;
}

print "Creating txt form...\n";
system "$textify $mdfile > $txtfile";

if ( prompt( 'Test links? (y/n)', 'y' ) eq 'y' ) {
    chomp( my @lines = $txtfile->lines_utf8 );
    foreach my $line (@lines) {
        $line =~ qr{^\s+\d+\.\s(https?://.+)$}xms
            or next;

        my $url = $1;

        print "[$url]:\n";
        my $html = wq($url);
        if ( !$html ) {
            print colored( ['red'], "Error fetching\n\n" );
            next;
        }

        my $title = $html->find('title')->first->text;
        if ( $title =~ /RT error/i ) {
            print colored( ['red'], "Error: $title\n" );
        } else {
            print colored( ['green'], "\t $title\n" );
        }

        print "\n";
    }
}

print "Preparing message for release\n";
my $release_notes = path('release_notes.txt');

if ( $release_notes->exists ) {
    print "Sorry, $release_notes already exists!\n";
    my $answer = prompt( 'Remove it? (y/n)', 'y' );
    $answer ne 'y' and die "Then we're out.\n";
    $release_notes->remove;
}

my $dates = ( $txtfile->lines_utf8( { 'count' => 1 } ) )[0] =~ s{(^\s+|\n)}{}r;
my $title = "Perl 5 Porters Mailing List Summary: $dates";

my $desc = qq{Hey everyone,\n\n} .
           q{Following is the p5p (Perl 5 Porters) mailing list summary } .
           qq{for the past week.\n\n} . 
           q{Enjoy!};

$release_notes->spew_utf8("Title:\n\n$title\n\nDescription:\n\n$desc\n");

system "gedit $release_notes $mdfile $txtfile";

print "\n\nRemoved release notes file.\n" .
      "Done!\n";

$release_notes->remove;

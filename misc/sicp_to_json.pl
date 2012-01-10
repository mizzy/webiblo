#!/usr/bin/perl

use strict;
use warnings;
use LWP::Simple;
use HTML::TreeBuilder::XPath;
use JSON::XS;

my $base = 'http://mitpress.mit.edu/sicp/full-text/book';

my $book = {
    title         => 'Structure and Interpretation of Computer Programs',
    authors       => [ 'Harold Abelson', 'Gerald Jay Sussman', 'Julie Sussman' ],
    cover_image   => 'http://mitpress.mit.edu/sicp/full-text/book/cover.jpg',
    exclude_xpath => q{//div[@class="navigation"]},
};

my $chapters = [];

my $contents = get('http://mitpress.mit.edu/sicp/full-text/book/book-Z-H-4.html');

my $tree = HTML::TreeBuilder::XPath->new;
$tree->parse($contents);
$tree->eof;

for my $a ( $tree->findnodes('//a') ) {
    my $name = $a->attr('name');
    next if !$name or $name !~ /\%_toc/ or $name eq '%_toc_start';

    my $text = $a->as_text;
    $text =~ s/\240/ /g;
    my $href = "$base/" . $a->attr('href');

    if ( $name =~ /^\%_toc_\%_chap_Temp/ ) {
        push @$chapters, {
            title => $text,
            uri   => $href,
        };
        next;
    }
    # entering the chapter
    elsif ( $name =~ /^\%_toc_\%_chap_\d$/ ) {
        push @$chapters, {
            title    => $text,
            uri      => $href,
            sections => [],
        };
    }
    # entering the section
    elsif ( $name =~ /\%_toc_\%_sec_\d\.\d$/ ) {
        push @{ $chapters->[-1]->{sections} }, {
            title       => $text,
            uri         => $href,
            subsections => [],
        };
    }
    # entring the subsection
    elsif ( $name =~ /\%_toc_\%_sec_\d\.\d\.\d$/ ) {
        push @{ $chapters->[-1]->{sections}->[-1]->{subsections} }, {
            title => $text,
            uri   => $href,
        };
    }
}

$book->{chapters} = $chapters;

my $json = JSON::XS->new;
$json->indent(1);

print $json->encode($book);


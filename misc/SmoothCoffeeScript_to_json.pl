#!/usr/bin/perl

use strict;
use warnings;
use LWP::Simple;
use HTML::TreeBuilder::XPath;
use JSON::XS;

my $base = 'http://autotelicum.github.com/Smooth-CoffeeScript/SmoothCoffeeScript.html';

my $content = get('http://autotelicum.github.com/Smooth-CoffeeScript/SmoothCoffeeScript.html');

my $tree = HTML::TreeBuilder::XPath->new;
$tree->no_expand_entities(1);
$tree->parse($content);
$tree->eof;

my $book = {
    title       => ($tree->findnodes('//title'))[0]->as_text,
    author      => ($tree->findnodes('//div[@class="author"]'))[0]->as_text,
    cover_image => 'http://autotelicum.github.com/Smooth-CoffeeScript/img/SmoothCoverWithSolutions.jpg',
};

my $parts = [];

for my $a ( $tree->findnodes('//a[@class="Link"]') ) {
    my $href  = $a->attr('href');
    my $title = $a->as_text;

    next if $href !~ /^#toc/ and $href !~ /^#Index/;

    if ( $href =~ /^#toc-Part/ or $href eq '#Index' ) {
        push @$parts, {
            title    => $title,
            uri      => $base . $href,
            chapters => [],
        };
    }
    elsif ( $href =~ /^#toc-Chapter/ or $href =~ /^#toc-Appendix/ ) {
        push @{ $parts->[-1]->{chapters} }, {
            title    => $title,
            uri      => $base. $href,
            sections => [],
        };
    }
    elsif ( $href =~ /^#toc-Section/ ) {
        push @{ $parts->[-1]->{chapters}->[-1]->{sections} }, {
            title       => $title,
            uri         => $base. $href,
            subsections => [],
        };
    }
    elsif ( $href =~ /^#toc-Subsection/ ) {
        push @{ $parts->[-1]->{chapters}->[-1]->{sections}->[-1]->{subsections} }, {
            title => $title,
            uri   => $base. $href,
        };
    }
}

$book->{parts} = $parts;

my $json = JSON::XS->new;
$json->indent(1);

print $json->encode($book);

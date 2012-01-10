#!/usr/bin/perl

use strict;
use warnings;
use JSON::Syck;
use LWP::Simple;
use URI;
use HTML::TreeBuilder::XPath;
use Text::Xslate;
use Image::Resize;

my $style = HTML::Element->new('style');
$style->attr('type', 'text/css');
$style->push_content(<<STYLE);
h1, h2, h3, h4, h5, h6, p, ul, ol, dl, pre, blockquote, table
{margin-top:0.6em; text-indent:0em;}
.font_size
{font-size:x-large;}
STYLE

my $book = JSON::Syck::Load(do { local $/; <STDIN>});

mkdir 'tmp' unless -d 'tmp';
mkdir 'out' unless -d 'out';

# Get cover image
if ( $book->{cover_image} ) {
    my $uri  = URI->new($book->{cover_image});
    my $file = ($uri->path_segments)[-1];
    mirror($uri, "out/$file") unless -f "out/$file";
    $book->{cover_file} = $file;
    my $image = Image::Resize->new("out/$file");
    my $gd = $image->resize(600, 800);
    open my $out, '>', "out/$file" or die $!;
    print $out $gd->jpeg;
    close $out;
}

for my $chapter ( @{ $book->{chapters} } ) {
    get_content($chapter);
    for my $section ( @{ $chapter->{sections} } ) {
        get_content($section);
        for my $subsection ( @{ $section->{subsections} } ) {
            get_content($subsection);
        }
    }
}

my $tx = Text::Xslate->new( syntax => 'TTerse' );

warn "Writing index.html ...\n";
open my $out, '>', 'out/index.html' or die $!;
print $out $tx->render('index.tx', $book);
close $out;

warn "Writing toc.ncx ...\n";
open $out, '>', 'out/toc.ncx' or die $!;
print $out $tx->render('ncx.tx', $book);
close $out;

my $book_title = $book->{title};
$book_title =~ s/\s/_/g;

warn "Writing ${book_title}.opf ...\n";
open $out, '>', "out/${book_title}.opf" or die $!;
print $out $tx->render('opf.tx', $book);
close $out;

warn "Executing kindlegen ...\n";
`kindlegen out/${book_title}.opf`;

exit;

sub get_content {
    my $object = shift;
    return if !$object->{uri};

    warn "Getting $object->{title} ...\n";

    my $uri      = URI->new($object->{uri});
    my $file     = ($uri->path_segments)[-1];
    my $fragment = $uri->fragment;

    mirror($uri, "tmp/$file") unless -f "tmp/$file";

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_file("tmp/$file");

    if ( $book->{content_xpath} ) {
        my $content = ($tree->findnodes($book->{content_xpath}))[0];
        $tree = HTML::TreeBuilder::XPath->new;
        $tree->parse($content->as_XML);
        $tree->eof;
    }

    if ( $book->{exclude_xpath} ) {
        my @excludes = ($tree->findnodes($book->{exclude_xpath}));
        for my $exclude ( @excludes ) {
            $exclude->detach;
        }
    }

    my $head = ($tree->findnodes('/html/head'))[0];
    $head->push_content($style);

    my @images = $tree->findnodes('//img');
    for my $image ( @images ) {
        my $base = $uri->as_string;
        $base =~ s{/[^/]+$}{};
        get_image(URI->new("$base/" . $image->attr('src')));
    }

    $file =~ s/\..+/.html/ unless $file =~ /\.html$/;

    open my $out, '>', "out/$file" or die $!;
    print $out $tree->as_XML;
    close $out;

    $object->{file} = $file;
    $file .= "#$fragment" if $fragment;
    $object->{href} = $file;
}

sub get_image {
    my $uri = shift;
    warn "Getting $uri ...\n";
    my $file = ($uri->path_segments)[-1];
    mirror($uri, "out/$file") unless -f "out/$file";
}

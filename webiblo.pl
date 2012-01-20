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

my $uri  = shift;
my $book = $uri ? JSON::Syck::Load(get($uri)) : JSON::Syck::Load(do { local $/; <STDIN> });

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

$book->{parts}->[0]->{chapters} = $book->{chapters} unless $book->{parts};

for my $part ( @{ $book->{parts} } ) {
    get_content($part);
    for my $chapter ( @{ $part->{chapters} } ) {
        get_content($chapter);
        for my $section ( @{ $chapter->{sections} } ) {
            get_content($section);
            for my $subsection ( @{ $section->{subsections} } ) {
                get_content($subsection);
            }
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

set_startup_page($book);

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

    my $uri      = URI->new($object->{uri});
    my $file     = ($uri->path_segments)[-1];
    my $fragment = $uri->fragment;

    $file =~ s/\..+/.html/ unless $file =~ /\.html$/;
    $object->{file} = $file;
    $object->{href} = $fragment ? "$file#$fragment" : $file;

    return if -f "tmp/$file";

    warn "Getting $object->{title} ...\n";
    mirror($uri, "tmp/$file");

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->no_expand_entities(1);
    $tree->parse_file("tmp/$file");
    $tree->eof;

    if ( $book->{content_xpath} ) {
        my $content = ($tree->findnodes($book->{content_xpath}))[0]->as_XML;
        my $meta = join '', map { $_->as_XML } $tree->findnodes('//head/meta');
        $tree = HTML::TreeBuilder::XPath->new;
        $tree->no_expand_entities(1);
        $tree->parse(<<"HTML");
          <html>
            <head>
              $meta
            </head>
            <body>
              $content
            </body>
          </html>
HTML
        $tree->eof;
    }

    if ( $book->{exclude_xpath} ) {
        my @excludes = ($tree->findnodes($book->{exclude_xpath}));
        for my $exclude ( @excludes ) {
            $exclude->detach;
        }
    }

    my @links = $tree->findnodes('//link[@rel="stylesheet"]');
    for my $link ( @links ) {
        warn "Getting $uri ...\n";
        my $href = $link->attr('href');
        my $base = $uri->as_string;
        $base =~ s{/[^/]+$}{};
        $href = "$base/$href" if $href !~ m!^https?://!;
        my $file = (URI->new($href)->path_segments)[-1];
        mirror($href, "out/$file") unless -f "out/$file";
    }

    if ( ! scalar @links ) {
        my $head = ($tree->findnodes('/html/head'))[0];
        $head->push_content($style)
    };

    my @images = $tree->findnodes('//img');
    for my $image ( @images ) {
        warn "Getting $uri ...\n";
        my $src = $image->attr('src');
        my $base = $uri->as_string;
        $base =~ s{/[^/]+$}{};
        $src = "$base/$src" if $src !~ m!^https?://!;
        my $file = (URI->new($src)->path_segments)[-1];
        mirror($src, "out/$file") unless -f "out/$file";
        $image->attr('src', $file);
    }

    open my $out, '>', "out/$file" or die $!;
    print $out $tree->as_XML;
    close $out;
}

sub set_startup_page {
    my $book = shift;

    for my $part ( @{ $book->{parts} } ) {
        if ( $part->{href} ) {
            $book->{startup_page} = $part->{href};
            return;
        }
        for my $chapter ( @{ $part->{chapters} } ) {
            if ( $chapter->{href} ) {
                $book->{startup_page} = $chapter->{href};
                return;
                for my $section ( @{ $chapter->{sections} } ) {
                    if ( $section->{href} ) {
                        $book->{startup_page} = $section->{href};
                        return;
                    }
                    for my $subsection ( @{ $section->{subsections} } ) {
                        if ( $subsection->{href} ) {
                            $book->{startup_page} = $subsection->{href};
                            return;
                        }
                    }
                }
            }
        }
    }
}

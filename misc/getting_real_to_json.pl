#!/usr/bin/perl

use strict;
use warnings;

use JSON::XS;
use LWP::Simple;
use HTML::TreeBuilder::XPath;
use YAML;


my $base = 'http://gettingreal.37signals.com';
my $tree = HTML::TreeBuilder::XPath->new;
$tree->parse(get("$base/toc.php"));

my $chapters = [];
for my $chapter ( $tree->findnodes('//h2') ) {
    my @contents = $chapter->content_list;
    my $name = $contents[0]->attr('name');
    next if !$name or $name !~ /^ch\d+/;
    my $title = $contents[1];
    $title =~ s/\s+$//;

    my $sections = [];
    for my $section ( $chapter->right->findnodes('li/a') ) {
        push @$sections, {
            uri   => $base . '/' . $section->attr('href'),
            title => $section->as_text,
        };
    }

    push @$chapters, {
        title    => $title,
        sections => $sections,
    };
}

my $json = JSON::XS->new;
$json->indent(1);

print $json->encode({
    title         => 'Getting Real',
    authors       => ['37signals'],
    date          => '2012/1/9',
    chapters      => $chapters,
    content_xpath => q{//div[@class="content"]},
    exclude_xpath => q{//div[@class="next"]},
    cover_image   => 'http://ec2.images-amazon.com/images/I/31jvYr2h6GL._SS500_.jpg',
});

exit;

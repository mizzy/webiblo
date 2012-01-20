#!/usr/bin/env perl

use strict;
use warnings;
#use utf8;
use Web::Query qw(wq);
use Data::Section::Simple qw(get_data_section);
use JSON::XS qw(encode_json);
use YAML::Syck;

my $sec_i = 0;

my $meta = {
    title => '英語上達完全マップ',
    author => '森沢 洋介',
    cover_image => 'http://images-jp.amazon.com/images/P/4860641027.01.LZZZZZZZ.jpg',
    content_xpath => '//body/table//tr[count(preceding-sibling::*) = 4 and parent::*]',
    exclude_xpath => '//body/table//tr[count(preceding-sibling::*) = 3 and parent::*]',
    chapters => [],
};

my $data = YAML::Syck::Load do { local $/; <DATA> };

for (my $i = 0; ; $i++) {
    my $data = $data->[$i] or last;
    my ($title, $uri, $sec) = @{$data};
    my $chapter = {};
    $chapter->{title} = $title;
    $chapter->{uri} = $uri if $uri;
    $chapter->{sections} = do {
        my @secs;
        while (my ($title, $uri) = splice @{$sec}, 0, 2) {
            push @secs, {
                title => $title,
                ($uri ? ('uri', $uri) : ()),
            };
        }
        \@secs;
    };
    push @{$meta->{chapters}}, $chapter;
}

my $json = JSON::XS->new;
$json->indent(1);
print $json->encode($meta);

__DATA__
---
-
  - はじめに
  - http://homepage3.nifty.com/mutuno/01_first/01_first.html
-
  - 英語のテスト特にTOEICについて
  - http://homepage3.nifty.com/mutuno/02_toeic/02_toeic.html
-
  - 英語は日本で上達する
  - http://homepage3.nifty.com/mutuno/03_japan/03_japan.html
-
  - 英語力を解剖する
  - http://homepage3.nifty.com/mutuno/04_dissect/04_dissect.html
-
  - 英語トレーニング法
  - http://homepage3.nifty.com/mutuno/05_training/05_training.html
  -
    - 音読パッケージ
    - HTtp://homepage3.nifty.com/mutuno/05_training/05_training01.html
    - 瞬間英作文
    - HTtp://homepage3.nifty.com/mutuno/05_training/05_training02.html
    - 文法
    - HTtp://homepage3.nifty.com/mutuno/05_training/05_training03.html
    - 精読
    - HTtp://homepage3.nifty.com/mutuno/05_training/05_training04.html
    - 多読（速読）
    - HTtp://homepage3.nifty.com/mutuno/05_training/05_training05.html
    - 語彙増強＝ボキャビル
    - HTtp://homepage3.nifty.com/mutuno/05_training/05_training06.html
    - リスニング
    - HTtp://homepage3.nifty.com/mutuno/05_training/05_training07.html
    - 会話
    - HTtp://homepage3.nifty.com/mutuno/05_training/05_training08.html
-
  - トレーニングの進め方
  - http://homepage3.nifty.com/mutuno/06_case/06_case.html
  -
    - 標準ケース
    - http://homepage3.nifty.com/mutuno/06_case/06_case01.html
    - 実例ケース
    - http://homepage3.nifty.com/mutuno/06_case/06_case02.html
    - 目的・タイプ別ケース
    - http://homepage3.nifty.com/mutuno/06_case/06_case03.html
-
  - トレーニングを継続するために
  - http://homepage3.nifty.com/mutuno/07_continue/07_continue.html
-
  - おすすめ教材集
  - http://homepage3.nifty.com/mutuno/08_book/08_book.html
-
  - アドバイス集
  - http://homepage3.nifty.com/mutuno/09_advice/09_advice.html
-
  - Q & A
  - http://homepage3.nifty.com/mutuno/10_QA/10_QA.html
-
  - 教室案内
  - http://homepage3.nifty.com/mutuno/11_school/11_school.html
-
  - リンク
  - http://homepage3.nifty.com/mutuno/12_link/12_link.html

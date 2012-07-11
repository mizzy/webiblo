# -*- coding: utf-8 -*-
%w(uri json nokogiri curb cgi).each {|g| require g }

root = 'http://i.loveruby.net/ja/rhg/book/'
book = {
  :title         => 'Rubyソースコード完全解説',
  :authors       => [ 'Minero Aoki' ],
  :cover_image   => 'http://direct.ips.co.jp/directsys/Images/Goods/1/1721B.gif',
  :content_xpath => '//body',
  :chapters      => []
}

def curl(url)
  c = Curl::Easy.new(url.to_s)
  c.follow_location = true
  c.perform
  c.body_str
end

doc = Nokogiri::HTML(curl(root))
doc.xpath('//ul/li/a').each do |a|
  chapter_url = URI(root) + a[:href]
  chapter = {
    :uri   => chapter_url,
    :title => a.text,
  }
  book[:chapters] << chapter
end

puts JSON.pretty_generate(book)

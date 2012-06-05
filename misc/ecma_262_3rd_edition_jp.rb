%w/uri json nokogiri curb cgi/.each {|g| require g }

root = 'http://www2u.biglobe.ne.jp/~oz-07ams/prog/ecma262r3/fulltoc.html'
book = {
  :title => 'ECMA-262 3rd edition',
  :authors => [
    'TAKI'
  ],
  :cover_image => 'http://www.ecma-international.org/images/logo_printerf.jpg',
  :content_xpath => '//div[@class="section level1"]',
  :chapters => []
}

def curl(url)
  c = Curl::Easy.new(url.to_s)
  c.follow_location = true
  c.perform
  c.body_str
end

doc = Nokogiri::HTML(curl(root))
doc.xpath('//body/dl/dt/a').each do |a|
  chapter_url = URI(root) + a[:href]
  chapter = {
    :uri => chapter_url,
    :title => a.text,
  }
  book[:chapters] << chapter
end

puts book.to_json

%w(uri json nokogiri curb cgi).each {|g| require g }

root = 'http://guides.rubygems.org'
book = {
  :title         => 'RubyGems Guides',
  :authors       => %w( rubygems ),
  :cover_image   => 'http://guides.rubygems.org/images/logo.png',
  :content_xpath => '//section[@id="chapters"]',
  :chapters      => []
}

def curl(url)
  c = Curl::Easy.new(url.to_s)
  c.follow_location = true
  c.perform
  c.body_str
end

doc = Nokogiri::HTML(curl(root))
doc.xpath('//section[@id="chapters"]/h2/a').each do |a|
  chapter_url = URI(root) + a[:href]
  chapter = {
    :uri   => chapter_url,
    :title => a.text,
  }
  book[:chapters] << chapter
end

puts JSON.pretty_generate(book)

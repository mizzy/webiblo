%w/uri json nokogiri curb cgi/.each {|g| require g }

root = 'http://clojure.org/'
book = {
  :title => 'Clojure',
  :authors => [
    'Rich Hickey'
  ],
  :cover_image => 'http://clojure.org/space/showimage/clojure-icon.gif',
  :content_xpath => '//div[@id="content_view"]',
  :exclude_xpath => '//div[@id="toc"]',
  :chapters => []
}

def curl(url)
  c = Curl::Easy.new(url.to_s)
  c.follow_location = true
  c.perform
  c.body_str
end

def sections(url)
  sections = []
  doc = Nokogiri::HTML(curl(url))
  doc.xpath('//div[@id="toc"]//a').each do |a|
    if a[:href] =~ /^#/
        sections << {
        :uri => url.to_s + a[:href],
        :title => a.text
      }
    end
  end

  sections
end

doc = Nokogiri::HTML(curl(root))
doc.xpath('//div[@class="WikiCustomNav WikiElement wiki"]//a').each do |a|
  next if a[:href] =~ /^http/
  chapter_url = URI(root) + a[:href]
  chapter = {
    :uri => chapter_url,
    :title => a.text,
    #:sections => sections(chapter_url)
  }
  book[:chapters] << chapter
end

puts book.to_json

class String

  def to_html
    doc = Nokogiri::HTML.fragment(Kramdown::Document.new(self).to_html)
    doc = doc.at_xpath('p').children unless self =~ /\n/
    doc.to_html
  end

end
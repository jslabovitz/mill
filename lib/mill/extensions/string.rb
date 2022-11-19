class String

  Converters = {
    nil => proc { |t| RubyPants.new(t) },
    smart_quotes: proc { |t| RubyPants.new(t) },
    markdown: proc { |t| Kramdown::Document.new(t) },
    textile: proc { |t| RedCloth.new(t, [:no_span_caps]) },
  }

  def to_html(options={})
    converter = Converters[options[:mode]] or raise "Unknown to_html mode: #{options[:mode].inspect}"
    html = converter.call(self).to_html
    doc = Nokogiri::HTML5::DocumentFragment.parse(html)
    if !options[:multiline] && (p_elem = doc.at_xpath('p'))
      doc = p_elem.children.to_html
    end
    doc.to_html
  end

end
class String

  Converters = {
    nil => RubyPants,
    smart_quotes: RubyPants,
    markdown: Kramdown::Document,
    textile: [RedCloth, :no_span_caps],
  }

  def to_html(options={})
    converter_class = Converters[options[:mode]] or raise "Unknown to_html mode: #{options[:mode].inspect}"
    if converter_class.kind_of?(Array)
      converter_class, *converter_options = *converter_class
      converter = converter_class.new(self, converter_options)
    else
      converter = converter_class.new(self)
    end
    html = Nokogiri::HTML5::DocumentFragment.parse(converter.to_html)
    if !options[:multiline] && (p_elem = html.at_xpath('p'))
      html = p_elem.children.to_html
    end
    html.to_html
  end

end
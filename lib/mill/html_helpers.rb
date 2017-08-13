module HTMLHelpers

  LinkElementsXPath = '//@href | //@src'

  def html_document(type=:html4_transitional, &block)
    doc = Nokogiri::HTML::Document.new
    doc.encoding = 'UTF-8'
    doc.internal_subset.remove
    case type
    when :html4_transitional
      doc.create_internal_subset('html', '-//W3C//DTD HTML 4.01 Transitional//EN', 'http://www.w3.org/TR/html4/loose.dtd')
    when :html5
      doc.create_internal_subset('html', nil, nil)
    else
      raise "Unknown HTML type: #{type.inspect}"
    end
    Nokogiri::HTML::Builder.with(doc) do |doc|
      yield(doc)
    end
    doc
  end

  def html_fragment(&block)
    html = Nokogiri::HTML::DocumentFragment.parse('')
    Nokogiri::HTML::Builder.with(html) do |html|
      yield(html) if block_given?
    end
    html
  end

  def parse_html(str)
    if str.strip.empty?
      html = html_fragment
    else
      html = Nokogiri::HTML::Document.parse(str) { |config| config.strict }
      html.errors.each do |error|
        raise Mill::Error, "HTML error #{error}" unless error.message =~ /Tag .+? invalid$/
      end
    end
    html
  end

  def find_link_elements(html)
    html.xpath(LinkElementsXPath)
  end

  def replace_element(html, xpath, &block)
    html.xpath(xpath).each do |elem|
      elem.replace(yield(elem))
    end
  end

  def amazon_button(asin)
    html_fragment do |html|
      html.a(href: "http://www.amazon.com/dp/#{asin}") do
        html.img(src: '/images/buy1._V46787834_.gif', alt: 'Buy from Amazon.com')
      end
    end
  end

  def paypal_button(id)
    html_fragment do |html|
      html.form(action: 'https://www.paypal.com/cgi-bin/webscr', method: 'post') do
        html.input(
          type: 'hidden',
          name: 'cmd',
          value: '_s-xclick')
        html.input(
          type: 'hidden',
          name: 'hosted_button_id',
          value: id)
        html.input(
          type: 'image',
          src: 'https://www.paypalobjects.com/en_US/i/btn/btn_buynow_LG.gif',
          name: 'submit',
          alt: 'PayPal - The safer, easier way to pay online!')
        html.img(
          alt: '',
          border: 0,
          width: 1,
          height: 1,
          src: 'https://www.paypalobjects.com/en_US/i/scr/pixel.gif')
      end
    end
  end

  def google_analytics(tracker_id)
    html_fragment do |html|
      html.script(type: 'text/javascript') do
        html << %Q{
          var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
          document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
        }
      end
      html.script(type: 'text/javascript') do
        html << %Q{
          try {
            var pageTracker = _gat._getTracker("#{tracker_id}");
            pageTracker._trackPageview();
          } catch(err) {}
        }
      end
    end
  end

  def link_if(state, html, &block)
    elem = html_fragment { |h| yield(h) }
    if state
      html.a(href: uri) { html << elem.to_html }
    else
      html << elem.to_html
    end
  end

  class PreText < String

    def to_html
      html_fragment do |html|
        html.pre(self)
      end
    end

  end

  class ::String

    Converters = {
      nil => RubyPants,
      smart_quotes: RubyPants,
      markdown: Kramdown::Document,
      textile: RedCloth,
      pre: PreText,
    }

    def to_html(options={})
      converter = Converters[options[:mode]] or raise "Unknown to_html mode: #{options[:mode].inspect}"
      html = Nokogiri::HTML::DocumentFragment.parse(converter.new(self).to_html)
      if !options[:multiline] && (p_elem = html.at_xpath('p'))
        html = p_elem.children.to_html
      end
      html.to_html
    end

  end

end
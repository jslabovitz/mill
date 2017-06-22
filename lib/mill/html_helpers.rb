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
      yield(html)
    end
    html
  end

  def parse_html(str)
    html = Nokogiri::HTML::Document.parse(str) { |config| config.strict }
    html.errors.each do |error|
      raise "HTML error #{error}" unless error.message =~ /Tag .+? invalid$/
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

  class PreText < String

    def to_html
      html_fragment do |html|
        html.pre(self)
      end
    end

  end

  class ::String

    def to_html(options={})
      html_str = case options[:mode]
      when nil, :smart_quotes
        RubyPants.new(self).to_html
      when :markdown
        Kramdown::Document.new(self).to_html
      when :textile
        RedCloth.new(self).to_html
      when :pre
        PreText.new(self).to_html
      else
        raise "Unknown to_html mode: #{options[:mode].inspect}"
      end
      html = Nokogiri::HTML::DocumentFragment.parse(html_str)
      if options[:multiline]
        html.to_html
      else
        if (elem = html.at_xpath('p'))
          elem.children.to_html
        else
          html.to_html
        end
      end
    end

  end

end
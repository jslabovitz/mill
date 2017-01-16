module HTMLHelpers

  LinkElementsXPath = '//@href | //@src'

  def html_document(&block)
    builder = Nokogiri::HTML::Builder.new(encoding: 'utf-8') do |doc|
      yield(doc)
    end
    builder.doc
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
      next if error.message =~ /^Tag (.*?) invalid$/
      raise Error, "HTML error at line #{error.line}, column #{error.column}: #{error.message}"
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

    def to_html
      Nokogiri::HTML::DocumentFragment.parse(RubyPants.new(self).to_html).to_html
    end

  end

end
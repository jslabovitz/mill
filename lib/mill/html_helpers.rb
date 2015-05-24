module HTMLHelpers

  class HTMLError < Exception; end

  IgnoreErrors = %Q{
    <table> lacks "summary" attribute
    <img> lacks "alt" attribute
    <form> proprietary attribute "novalidate"
    <input> attribute "type" has invalid value "email"
    <input> attribute "tabindex" has invalid value "-1"
  }.split(/\n/).map(&:strip)

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
      raise HTMLError, "HTML error at line #{error.line}, column #{error.column}: #{error.message}"
    end
    html
  end

  def tidy_html(html, &block)
    html_str = html.to_s
    tidy = TidyFFI::Tidy.new(html_str, char_encoding: 'UTF8')
    errors = parse_tidy_errors(tidy).reject do |error|
      IgnoreErrors.include?(error[:error])
    end
    unless errors.empty?
      full_error = StringIO.new('')
      full_error.puts "invalid HTML:"
      html_lines = html_str.split(/\n/)
      errors.each do |error|
        full_error.puts "\t#{error[:msg]}:"
        html_lines.each_with_index do |html_line, i|
          if i >= [0, error[:line] - 2].max && i <= [error[:line] + 2, html_lines.length].min
            if i == error[:line]
              output = [
                error[:column] > 0 ? (html_line[0 .. error[:column] - 1]) : '',
                Term::ANSIColor.negative,
                html_line[error[:column]],
                Term::ANSIColor.clear,
                html_line[error[:column] + 1 .. -1],
              ]
            else
              output = [html_line]
            end
            full_error.puts "\t\t%3s: %s" % [i + 1, output.join]
          end
        end
        if block_given?
          yield(full_error.string)
        else
          STDERR.print(full_error.string)
        end
        raise HTMLError, "HTML error: #{error[:msg]}" if error[:type] == :error
      end
    end
  end

  def parse_tidy_errors(tidy)
    return [] unless tidy.errors
    tidy.errors.split(/\n/).map do |error_str|
      error_str =~ /^line (\d+) column (\d+) - (.*?): (.*)$/ or raise "Can't parse error: #{error_str}"
      {
        msg: error_str,
        line: $1.to_i - 1,
        column: $2.to_i - 1,
        type: $3.downcase.to_sym,
        error: $4.strip,
      }
    end
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
      if empty?
        self
      else
        Nokogiri::HTML::DocumentFragment.parse(Kramdown::Document.new(self).to_html).at_xpath('p').children.to_html
      end
    end

  end

end
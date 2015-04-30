class Mill

  class Resource

    class HTML < Resource

      class HTMLError < Exception; end

      attr_accessor :title

      def self.file_extensions
        %w{
          .html
          .htm
        }
      end

      def self.custom_elements
        []
      end

      def initialize(params={})
        super({public: true}.merge(params))
      end

      def parse_html(str)
        html = Nokogiri::HTML(str) { |config| config.strict }
        html.errors.each do |error|
          next if error.message =~ /^Tag (.*?) invalid$/ && self.class.custom_elements.include?($1)
          raise HTMLError, "HTML error: #{error.line}:#{error.column}: #{error.message}"
        end
        html
      end

      def load
        load_date
        begin
          @content = parse_html(@input_file.read)
        rescue => e
          warn "failed to parse #{@input_file}: #{e}"
          raise e
        end
        load_html_header
      end

      def tidy
        html_str = @content.to_s
        tidy = TidyFFI::Tidy.new(html_str)
        if (str = tidy.errors)
          warn "#{uri}: invalid HTML:"
          html_lines = html_str.split(/\n/)
          str.split(/\n/).each do |error|
            if error =~ /^line (\d+) column (\d+) - (Error|Warning): (.*)$/
              line, column, type, msg = $1.to_i - 1, $2.to_i - 1, $3, $4
              warn "\t#{error}:"
              html_lines.each_with_index do |html_line, i|
                if i >= [0, line - 2].max && i <= [line + 2, html_lines.length].min
                  if i == line
                    output = [
                      column > 0 ? (html_line[0 .. column - 1]) : '',
                      Term::ANSIColor.negative,
                      html_line[column],
                      Term::ANSIColor.clear,
                      html_line[column + 1 .. -1],
                    ]
                  else
                    output = [html_line]
                  end
                  warn "\t\t%3s: %s" % [i + 1, output.join]
                end
              end
              raise "HTML error" if type == 'Error'
            else
              warn "\t" + error
            end
          end
        end
      end

      def build
        @content = @content.to_html(encoding: 'US-ASCII')
        tidy
        super
      end

      def load_html_header
        @title = @content.at_xpath('/html/head/title').text
        @content.xpath('/html/head/meta[@name]').each do |meta|
          begin
            send("#{meta['name']}=", meta['content'])
          rescue => e
            #FIXME: only rescue unknown symbols
            raise e
          end
        end
      end

      def replace_element(xpath, &block)
        @content.xpath(xpath).each do |elem|
          elem.replace(yield(elem))
        end
      end

      def add_external_link_targets
        @content.xpath('//a').each do |a|
          if a['href'] && a['href'] =~ /^\w+:/
            a['target'] = '_blank'
          end
        end
      end

      def add_image_sizes
        @content.xpath('//img').each do |img|
          # skip elements that already have width/height defined
          next if img[:width] || img[:height]
          img_link = Addressable::URI.parse(img['src'])
          raise "no link in <img> element: #{img.to_s}" if img_link.nil? || img_link.empty?
          next if img_link.host
          img_uri = uri + img_link
          img_resource = @mill[img_uri] or raise "Can't find image for #{img_uri}"
          img[:width], img[:height] = img_resource.width, img_resource.height
        end
      end

    end

  end

end
class Mill

  class Resource

    class Text < Resource

      include HTMLHelpers

      attr_accessor :title

      def self.type
        :text
      end

      def initialize(params={})
        super(
          {
            public: true,
          }.merge(params)
        )
      end

      def load
        if @input_file
          @content = @input_file.read
          markup_class = case @input_file.extname
          when '.md', '.mdown', '.markdown'
            Kramdown::Document
          when '.textile'
            RedCloth
          when '.txt'
            PreText
          else
            nil
          end
          if markup_class
            parse_text_header
            @content = markup_class.new(@content).to_html
            @output_file = @output_file.replace_extension('.html')
          end
          begin
            @content = parse_html(@content)
          rescue HTMLError => e
            raise "failed to parse #{@input_file}: #{e}"
          end
          parse_html_header
        end
        super
      end

      def parse_html_header
        if (title_elem = @content.at_xpath('/html/head/title'))
          @title = title_elem.text
        end
        @content.xpath('/html/head/meta[@name]').each do |meta|
          send("#{meta['name']}=", meta['content'])
        end
      end

      def parse_text_header
        if @content =~ /^\w+:\s+/
          header, @content = @content.split(/\n\n/, 2)
          header.split(/\n/).map do |line|
            key, value = line.strip.split(/:\s+/, 2)
            key = key.gsub('-', '_').downcase.to_sym
            send("#{key}=", value)
          end
        end
      end

      def final_content
        html_document do |doc|
          doc.html(lang: 'en') do |html|
            html.head do
              html << head.to_html
            end
            html.body do
              html << body.to_html
            end
          end
        end
      end

      def head
        @content.at_xpath('/html/head').children
      end

      def body
        @content.at_xpath('/html/body').children
      end

      def verify
        tidy_html(@output_file.read) do |error_str|
          warn "#{uri}: #{error_str}"
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
          img_resource = @mill.find_resource(img_uri) or raise "Can't find image for #{img_uri}"
          img[:width], img[:height] = img_resource.width, img_resource.height
        end
      end

      def feed_summary
        ;;raise "#{uri} has no content" unless @content
        if (p = @content.at_xpath('/html/body/p[1]'))
          ['html', p.to_html]
        else
          nil
        end
      end

      def feed_content
        ;;raise "#{uri} has no content" unless @content
        ['html', @content.at_xpath('/html/body').children.to_html]
      end

    end

  end

end
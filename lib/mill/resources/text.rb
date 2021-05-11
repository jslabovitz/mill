
module Mill

  class Resource

    class Text < Resource

      FileTypes = %w{
        text/plain
        text/html
        text/markdown
      }

      attr_accessor :title
      attr_accessor :summary
      attr_accessor :author
      attr_accessor :type

      def initialize(title: nil, summary: nil, author: nil, public: true, output_file: nil, **args)
        @title = title
        @summary = summary
        @author = author
        @type = nil
        super(
          public: public,
          output_file: output_file&.replace_extension('.html'),
          **args)
        if @path
          @path.sub!(%r{\.html$}, '') if @site&.shorten_uris
          @path.sub!(%r{(.*)index$}, '\1')
        end
      end

      def inspect
        super + ", title: %p, summary: %p, author: %p, type: %p" % [
          @title,
          @summary,
          @author,
          @type,
        ]
      end

      def load
        super
        if @input_file
          @content = @input_file.read
          @type = case @input_file.extname.downcase
          when '.md', '.mdown', '.markdown'
            :markdown
          when '.textile'
            :textile
          when '.txt'
            :pre
          when '.htm', '.html'
            :html
          else
            raise "Unknown text type: #{@input_file}"
          end
          if @type != :html
            parse_text_header
            @content = (@content || '').to_html(mode: @type, multiline: true)
            @type = :html
          end
          begin
            @content = parse_html(@content)
          rescue Error => e
            raise e, "#{@input_file}: #{e}"
          end
          parse_html_header
        end
      end

      def parse_html(str)
        if str.strip.empty?
          html = Simple::Builder.html_fragment
        else
          html = Nokogiri::HTML::Document.parse(str) { |config| config.strict }
          check_errors(html)
        end
        html
      end

      def parse_html_fragment(str)
        html = Nokogiri::HTML::DocumentFragment.parse(str) { |config| config.strict }
        check_errors(html)
        html
      end

      def parse_html_header
        @title ||= Simple::Builder.find_title(@content) || @path
        Simple::Builder.find_meta_tags(@content).each do |key, value|
          send("#{key}=", value)
        end
      end

      def parse_text_header
        if @content.split(/\n/, 2).first =~ /^\w+:\s+/
          header, @content = @content.split(/\n\n/, 2)
          header.split(/\n/).map do |line|
            key, value = line.strip.split(/:\s*/, 2)
            key = key.gsub('-', '_').downcase.to_sym
            send("#{key}=", value)
          end
        end
      end

      def check_errors(html)
        html.errors.each do |error|
          raise Mill::Error, "HTML error #{error}" unless error.message =~ /Tag .+? invalid$/
        end
      end

      def build
        post_process_html(@content) if respond_to?(:post_process_html)
      end

      def final_content
        type = case @site&.html_version
        when :html4
          :html4_document
        when :html5, nil
          :html5_document
        else
          raise "Unknown HTML version: #{@site&.html_version.inspect}"
        end
        Simple::Builder.send(type) do |doc|
          doc.html(lang: 'en') do |html|
            html.parent << head
            html.parent << body
          end
        end.to_html
      end

      def head(&block)
        Simple::Builder.html_fragment do |html|
          html.head do
            head = content_head
            if (title = @title || (head && head.at_xpath('title')))
              html.title { html << title.to_html }
            end
            yield(html) if block_given?
            if head
              head.children.reject { |e| e.text? || e.name == 'title' }.each do |e|
                html << e.to_html
              end
            end
          end
        end
      end

      def body(&block)
        Simple::Builder.html_fragment do |html|
          html.body do
            if (elem = content_body)
              html << elem.children.to_html
            end
            yield(html) if block_given?
          end
        end
      end

      def content_head
        @content && Simple::Builder.find_head(@content)
      end

      def content_body
        @content && Simple::Builder.find_body(@content)
      end

      def add_image_sizes
        @content.xpath('//img').each do |img|
          # skip elements that already have width/height defined
          next if img[:width] || img[:height]
          img_link = Addressable::URI.parse(img['src'])
          raise Error, "No link in <img> element: #{img.to_s}" if img_link.nil? || img_link.empty?
          next if img_link.host
          img_uri = uri + img_link
          img_resource = @site.find_resource(img_uri) or raise Error, "Can't find image for #{img_uri}"
          img[:width], img[:height] = img_resource.width, img_resource.height
        end
      end

      def shorten_links
        Simple::Builder.find_link_elements(@content).each do |attribute|
          elem = attribute.parent
          link_uri = Addressable::URI.parse(attribute.value) or raise Error, "Can't parse #{attribute.value.inspect} from #{xpath.inspect}"
          link_uri = uri + link_uri
          if link_uri.relative?
            self_uri = uri.normalize
            self_uri.scheme = 'http'
            link_uri.scheme = 'http'
            attribute.value = self_uri.route_to(link_uri)
            # ;;warn "[#{path}] shortened link #{elem.name}/@#{attribute.name}: #{link_uri} => #{attribute.value}"
          end
        end
      end

      def summary
        @summary || ((p = feed_content.at_xpath('//p')) && p.children)
      end

      def feed_content
        if (body = content_body)
          # If we have a main element (<div class="main"> or <main>), use that.
          # Otherwise, use the body, but delete header/footer/nav divs or elements.
          if (main = body.at_xpath('//div[@id="main"]')) || (main = body.at_xpath('//main'))
            main.children
          elsif (article = body.at_xpath('//article'))
            article.children
          else
            body_elem = body.clone
            %w{header nav masthead footer}.each do |name|
              if (elem = body_elem.at_xpath("//div[@id=\"#{name}\"]")) || (elem = body_elem.at_xpath("//#{name}"))
                elem.remove
              end
            end
            body_elem.children
          end
        else
          warn "Warning: Resource #{path} (#{self.class}) has no content"
          nil
        end
      end

    end

  end

end
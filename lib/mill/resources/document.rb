module Mill

  class Resource

    class Document < Resource

      FileTypes = %w{
        text/html
        text/markdown
        text/textile
      }

      attr_accessor :title
      attr_reader   :draft
      attr_reader   :hidden

      def initialize(params={})
        super
        @path.sub!(%r{\.\w+$}, '')
        @path.sub!(%r{/index$}, '/')
        @uri = Addressable::URI.encode(@path, Addressable::URI)
      end

      def draft=(state)
        @draft = case state
        when 'false', FalseClass
          false
        when 'true', TrueClass
          true
        else
          raise ArgumentError
        end
      end

      def draft?
        @draft == true
      end

      def hidden=(state)
        @hidden = case state
        when 'false', FalseClass
          false
        when 'true', TrueClass
          true
        else
          raise ArgumentError
        end
      end

      def hidden?
        @hidden == true
      end

      def inspect
        super + ", title: %p, draft: %p, hidden: %p" % [
          @title,
          @draft,
          @hidden,
        ]
      end

      def publish?
        !draft?
      end

      def advertise?
        publish? && !hidden?
      end

      def output_file
        if (file = super)
          file /= 'index' if @path.end_with?('/')
          file.add_extension('.html')
        end
      end

      def load
        super
        if @input
          case @input
          when Path
            @input_type = MIME::Types.of(@input.to_s).last
            text = @input.read
          when String
            raise unless @input_type
            text = @input.dup
          when Nokogiri::HTML4::Document
            @input_type = 'text/html'
            @document = @input
          else
            raise Error, "Unknown input: #{@input.class}"
          end
          case @input_type
          when 'text/markdown'
            header, text = parse_text_header(text)
            @document = Simple::Builder.parse_html_document(
              Kramdown::Document.new((text || '').strip).to_html)
          when 'text/textile'
            header, text = parse_text_header(text)
            @document = Simple::Builder.parse_html_document(
              RedCloth.new((text || '').strip, [:no_span_caps]).to_html)
          when 'text/html'
            @document ||= Simple::Builder.parse_html_document(text)
            header = parse_html_header(@document)
          else
            raise "Unknown/missing document type: #{@input_type.inspect}"
          end
          set(header)
        end
      end

      def parse_html_header(doc)
        Simple::Builder.find_meta_info(doc).merge(title: @title || Simple::Builder.find_title_element(doc)&.text)
      end

      def parse_text_header(text)
        header = {}
        if text.split(/\n/, 2).first =~ /^\w+:\s+/
          header, text = text.split(/\n\n/, 2)
          header = header.split(/\n/).map do |line|
            key, value = line.strip.split(/:\s*/, 2)
            key = key.gsub('-', '_').downcase.to_sym
            [key, value]
          end.to_h
        end
        [header, text]
      end

      def build
        builder = case @site&.html_version
        when :html4
          :build_html4_document
        when :html5, nil
          :build_html5_document
        else
          raise "Unknown HTML version: #{@site&.html_version.inspect}"
        end
        @output = Simple::Builder.send(builder) do |html|
          html.html(lang: 'en') do
            html.head do
              build_head(html)
            end
            html.body do
              build_body(html)
            end
          end
        end.to_html
      end

      def build_head(html)
        title = @title || Simple::Builder.find_title_element(@document)&.text
        html.title { html << title.to_html } if title
        if (head = document_head&.children)
          head.reject { |e| e.text? || e.name == 'title' }.each do |e|
            html << e.to_html
          end
        end
      end

      def build_body(html)
        if (elem = document_body&.children)
          html << elem.to_html
        end
      end

      def document_head
        Simple::Builder.find_head_element(@document)
      end

      def document_body
        Simple::Builder.find_body_element(@document)
      end

      def add_image_sizes
        @document.xpath('//img').each do |img|
          # skip elements that already have width/height defined
          next if img[:width] || img[:height]
          img_link = Addressable::URI.parse(img['src'])
          raise Error, "No link in <img> element: #{img.to_s}" if img_link.nil? || img_link.empty?
          next if img_link.host
          img_uri = @uri + img_link
          img_resource = @site.find_resource(img_uri) or raise Error, "Can't find image for #{img_uri}"
          img[:width], img[:height] = img_resource.width, img_resource.height
        end
      end

      def shorten_links
        Simple::Builder.find_link_element_attributes(@document).each do |attribute|
          link_uri = Addressable::URI.parse(attribute.value) or raise Error, "Can't parse attribute value: #{attribute.inspect}"
          link_uri = @uri + link_uri
          if link_uri.relative?
            self_uri = @uri.normalize
            self_uri.scheme = link_uri.scheme = @site.site_uri.scheme
            attribute.value = self_uri.route_to(link_uri)
            # ;;warn "[#{@path}] shortened link #{attribute.parent.name}/@#{attribute.name}: #{link_uri} => #{attribute.value}"
          end
        end
      end

      def feed_content
        document_body&.children
      end

      def build_link(html)
        html.a(href: @uri) { html << @title.to_html }
      end

      def check_links(external: false)
        attrs = Simple::Builder.find_link_element_attributes(@document)
        unless attrs.empty?
          attrs.map { |u| Addressable::URI.parse(u) }.each do |uri|
            uri = @uri + uri if uri.relative?
            uri.normalize!
            if uri.relative?
              unless @site.find_resource(uri.path)
                warn "#{@uri}: NOT FOUND: #{uri}"
              end
            elsif external && uri.absolute? && uri.scheme.start_with?('http')
              # warn "#{@uri}: checking external: #{uri}"
              begin
                check_external_uri(uri)
              rescue => e
                warn "#{@uri}: external URI: #{uri}: #{e}"
              end
            end
          end
        end
      end

      def check_external_uri(uri)
        response = HTTP.timeout(3).get(uri)
        case response.code
        when 200...300
          # ignore
        when 300...400
          redirect_uri = Addressable::URI.parse(response.headers['Location'])
          check_external_uri(uri + redirect_uri)
        when 404
          raise Error, "URI not found: #{uri}"
        when 999
          # ignore bogus LinkedIn status
        else
          raise Error, "Bad status: #{response.inspect}"
        end
      end

    end

  end

end
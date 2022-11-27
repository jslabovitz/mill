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
        if @input_file
          @content = @input_file.read
          case MIME::Types.of(@input_file.to_s).last
          when 'text/markdown'
            parse_text_header
            @content = Simple::Builder.parse_html_document(
              Kramdown::Document.new((@content || '').strip).to_html)
          when 'text/textile'
            parse_text_header
            @content = Simple::Builder.parse_html_document(
              RedCloth.new((@content || '').strip, [:no_span_caps]).to_html)
          when 'text/html'
            @content = Simple::Builder.parse_html_document(@content)
            parse_html_header
          else
            raise "Unknown document type: #{@input_file}"
          end
        end
      end

      def parse_html_header
        @title ||= Simple::Builder.title_element(@content)&.text
        set(Simple::Builder.find_meta_info(@content))
      end

      def parse_text_header
        if @content.split(/\n/, 2).first =~ /^\w+:\s+/
          header, @content = @content.split(/\n\n/, 2)
          params = header.split(/\n/).map do |line|
            key, value = line.strip.split(/:\s*/, 2)
            key = key.gsub('-', '_').downcase.to_sym
            [key, value]
          end.to_h
          set(params)
        end
      end

      def final_content
        builder = case @site&.html_version
        when :html4
          :build_html4_document
        when :html5, nil
          :build_html5_document
        else
          raise "Unknown HTML version: #{@site&.html_version.inspect}"
        end
        Simple::Builder.send(builder) do |doc|
          doc.html(lang: 'en') do |html|
            html.parent << head
            html.parent << body
          end
        end.to_html
      end

      def head(&block)
        Simple::Builder.build_html do |html|
          html.head do
            title = @title || Simple::Builder.find_title_element(@content)&.text
            html.title { html << title.to_html } if title
            yield(html) if block_given?
            if (head = content_head)
              head.children.reject { |e| e.text? || e.name == 'title' }.each do |e|
                html << e.to_html
              end
            end
          end
        end
      end

      def body(&block)
        Simple::Builder.build_html do |html|
          html.body do
            if (elem = content_body)
              html << elem.children.to_html
            end
            yield(html) if block_given?
          end
        end
      end

      def content_head
        @content && Simple::Builder.find_head_element(@content)
      end

      def content_body
        @content && Simple::Builder.find_body_element(@content)
      end

      def add_image_sizes
        @content.xpath('//img').each do |img|
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
        Simple::Builder.find_link_element_attributes(@content).each do |attribute|
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
        end
      end

      def make_link
        Simple::Builder.build_html do |html|
          html.a(href: @uri) { html << @title.to_html }
        end
      end

      def check_links(external: false)
        attrs = Simple::Builder.find_link_element_attributes(@content)
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
module Mill

  class Resource

    class Page < Resource

      FileTypes = %w{
        text/html
      }

      attr_accessor :title
      attr_reader   :hidden
      attr_reader   :document

      def initialize(params={})
        super
        @path.sub!(%r{\.\w+$}, '')
        @path.sub!(%r{/index$}, '/')
        @uri = Addressable::URI.encode(@path, Addressable::URI)
      end

      def hidden=(state)
        @hidden = case state
        when 'false', FalseClass, nil
          false
        when 'true', TrueClass
          true
        else
          raise ArgumentError, "Invalid hidden value: #{state.inspect}"
        end
      end

      def hidden?
        @hidden == true
      end

      def printable
        super + [
          :title,
          :hidden,
        ]
      end

      def advertise?
        !hidden?
      end

      def output_file
        if (file = super)
          file /= 'index' if @path.end_with?('/')
          file.add_extension('.html')
        end
      end

      def load
        @document = case @input
        when Path
          Simple::Builder.parse_html_document(@input.read)
        when String
          Simple::Builder.parse_html_document(@input)
        when Nokogiri::HTML4::Document
          @input
        else
          raise Error, "Unknown HTML input: #{@input.class}"
        end
        @title ||= @document.at_xpath('//h1')&.text || Simple::Builder.find_title_element(@document)&.text
        set(Simple::Builder.find_meta_info(@document))
      end

      def build
        raise Error, "No document defined" unless @document
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
        html.a(href: @uri) { html << (@title || @path).to_html }
      end

      def links
        raise "#{@path}: Can't get links for empty document: #{self}" unless @document
        Simple::Builder.find_link_element_attributes(@document).map do |u|
          (@uri + u).normalize
        end
      end

    end

  end

end
module Mill

  class Resource

    class Text < Resource

      FileTypes = %w{
        text/plain
        text/html
        text/markdown
      }

      attr_accessor :title
      attr_writer   :summary
      attr_accessor :author
      attr_reader   :public

      def initialize(title: nil, summary: nil, author: nil, public: true, output_file: nil, **args)
        @title = title
        @summary = summary
        @author = author
        @public = public
        super(
          output_file: output_file&.replace_extension('.html'),
          **args)
        if @path
          @path.sub!(%r{\.html$}, '') if @site&.shorten_uris
          @path.sub!(%r{(.*)index$}, '\1')
        end
      end

      def public=(public)
        @public = case public
        when 'false', FalseClass
          false
        when 'true', TrueClass
          true
        else
          raise Error, "Can't assign 'public' attribute: #{public.inspect}"
        end
      end

      def public?
        @public == true
      end

      def inspect
        super + ", title: %p, summary: %p, author: %p, public: %p" % [
          @title,
          @summary,
          @author,
          @public,
        ]
      end

      def load
        super
        if @input_file
          @content = @input_file.read
          case @input_file.extname.downcase
          when '.md', '.mdown', '.markdown'
            parse_text_header
            @content = Simple::Builder.markdown_to_html(@content)
          when '.textile'
            parse_text_header
            @content = Simple::Builder.textile_to_html(@content)
          when '.htm', '.html'
            parse_html_header
          else
            raise "Unknown text type: #{@input_file}"
          end
          begin
            @content = Simple::Builder.parse_html(@content)
          rescue Error => e
            raise e, "#{@input_file}: #{e}"
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
            title = @title || Simple::Builder.title_element&.text
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
          img_uri = uri + img_link
          img_resource = @site.find_resource(img_uri) or raise Error, "Can't find image for #{img_uri}"
          img[:width], img[:height] = img_resource.width, img_resource.height
        end
      end

      def shorten_links
        Simple::Builder.find_link_element_attributes(@content).each do |attribute|
          link_uri = Addressable::URI.parse(attribute.value) or raise Error, "Can't parse attribute value: #{attribute.inspect}"
          link_uri = uri + link_uri
          if link_uri.relative?
            self_uri = uri.normalize
            self_uri.scheme = 'http'
            link_uri.scheme = 'http'
            attribute.value = self_uri.route_to(link_uri)
            # ;;warn "[#{path}] shortened link #{attribute.parent.name}/@#{attribute.name}: #{link_uri} => #{attribute.value}"
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

      def home_page?
        @path == '/'
      end

      def children_pages
        children.select(&:text?)
      end

      def sibling_pages
        siblings.select(&:text?)
      end

    end

  end

end
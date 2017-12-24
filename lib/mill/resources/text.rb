module Mill

  class Resource

    class Text < Resource

      include HTMLHelpers

      FileTypes = %w{
        text/plain
        text/html
      }

      attr_accessor :title
      attr_accessor :summary
      attr_accessor :author

      def initialize(title: nil, summary: nil, author: nil, public: true, **args)
        @title = title
        @summary = summary
        @author = author
        super(public: public, **args)
      end

      def inspect
        super + ", title: %p, summary: %p, author: %p" % [
          @title,
          @summary,
          @author,
        ]
      end

      def load
        super
        if @input_file
          @content = @input_file.read
          mode = case @input_file.extname.downcase
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
          if mode != :html
            parse_text_header
            @content = (@content || '').to_html(mode: mode, multiline: true)
            @output_file = @output_file.replace_extension('.html')
          end
          begin
            @content = parse_html(@content)
          rescue Error => e
            raise e, "#{@input_file}: #{e}"
          end
          parse_html_header
        end
      end

      def parse_html_header
        unless @title
          if (title_elem = @content.at_xpath('/html/head/title'))
            @title = title_elem.text
          else
            @title = uri.to_s
          end
        end
        @content.xpath('/html/head/meta[@name]').each do |meta|
          send("#{meta['name']}=", meta['content'])
        end
      end

      def parse_text_header
        if @content.split(/\n/, 2).first =~ /^\w+:\s+/
          header, @content = @content.split(/\n\n/, 2)
          header.split(/\n/).map do |line|
            key, value = line.strip.split(/:\s+/, 2)
            key = key.gsub('-', '_').downcase.to_sym
            send("#{key}=", value)
          end
        end
      end

      def final_content
        html_document(@site.html_version) do |doc|
          doc.html(lang: 'en') do |html|
            html << head.to_html
            html << body.to_html
          end
        end.to_html
      end

      def head(&block)
        html_fragment do |html|
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
        html_fragment do |html|
          html.body do
            if (elem = content_body)
              html << elem.children.to_html
            end
            yield(html) if block_given?
          end
        end
      end

      def content_head
        @content && @content.at_xpath('/html/head')
      end

      def content_body
        @content && @content.at_xpath('/html/body')
      end

      def add_external_link_targets
        @content.xpath('//a').each do |a|
          if a['href'] && a['href'] =~ /^\w+:/
            a['target'] = '_blank'
            a['rel'] = 'noopener noreferrer'
          end
        end
      end

      def remove_comments
        @content.xpath('//comment()').each do |comment|
          comment.remove
        end
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
        find_link_elements(@content).each do |attribute|
          elem = attribute.parent
          link_uri = Addressable::URI.parse(attribute.value) or raise Error, "Can't parse #{attribute.value.inspect} from #{xpath.inspect}"
          link_uri = uri + link_uri
          if link_uri.relative?
            self_uri = uri.normalize
            self_uri.scheme = 'http'
            link_uri.scheme = 'http'
            attribute.value = self_uri.route_to(link_uri)
            # ;;warn "[#{uri}] shortened link #{elem.name}/@#{attribute.name}: #{link_uri} => #{attribute.value}"
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
          warn "Warning: Resource #{uri} (#{self.class}) has no content"
          nil
        end
      end

    end

  end

end
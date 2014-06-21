class Mill

  class Resource

    class HTML < Resource

      def load
        super
        read_file
        parse_html
      end

      def process
        add_image_sizes
        add_external_link_targets
      end

      def parse_html
        unless @data.kind_of?(Nokogiri::HTML::Document)
          log.debug(3) { "parsing HTML" }
          @data = Nokogiri::HTML(@data) { |config| config.strict }
          @data.errors.reject { |e| e.message =~ /Tag members? invalid/ }.each do |error|
            log.error { "#{@src_file}: Error in HTML: #{error.line}:#{error.column}: #{error.message}" }
          end
          @title = @data.at_xpath('/html/head/title').text
          @data.xpath('/html/head/meta[@name]').each do |meta_elem|
            name, content = meta_elem['name'], meta_elem['content']
            send("#{name}=", content)
          end
        end
      end

      def add_image_sizes
        log.debug(3) { "adding image sizes" }
        @data.xpath('//img').each do |img|
          img_link = Addressable::URI.parse(img['src'])
          next if img_link.host
          img_link = uri + img_link
          resources = Resource::Image.load_path(img_link.path, @processor, :jpeg)
          raise "Multiple resources for image link #{img_link}" if resources.length > 1
          img_resource = resources.first
          log.debug(4) { "#{img_resource.uri}: #{img_resource.width}x#{img_resource.height}" }
          img[:width], img[:height] = img_resource.width, img_resource.height
        end
      end

      def add_external_link_targets
        log.debug(3) { "adding link targets" }
        @data.xpath('//a').each do |a|
          if a['href'] && a['href'] =~ /^\w+:/
            log.debug(4) { "#{a['href']}" }
            a['target'] = '_blank'
          end
        end
      end

      def add_script(script)
        if script.kind_of?(Hash)
          elem = @data.create_element('script', script)
        else
          elem = @data.create_element('script') { |e| e.content = script }
        end
        @data.at_xpath('/html/head') << elem
      end

      def add_stylesheet(stylesheet)
        attrs = { rel: 'stylesheet', type: 'text/css' }
        if stylesheet.kind_of?(Hash)
          add_link(attrs.merge(stylesheet))
        else
          add_link(attrs) { stylesheet }
        end
      end

      def add_feed(feed)
        attrs = {
          rel: 'alternate',
          type: 'application/atom+xml',
          title: feed.title,
          href: feed.link,
        }
        add_link(attrs)
      end

      def add_link(attrs, &block)
        elem = @data.create_element('link', attrs) { e.content = yield if block_given? }
        @data.at_xpath('/html/head') << elem
      end

      def set_title(title)
        title_elem = @data.at_xpath('/html/head/title')
        title_elem.content = title
      end

      def wrap_body(&block)
        body = @data.at_xpath('/html/body')
        new_body = Nokogiri::HTML.fragment('')
        Nokogiri::HTML::Builder.with(new_body) do |builder|
          builder.body do
            yield(builder, body.children)
          end
        end
        body.replace(new_body)
      end

    end

  end

end
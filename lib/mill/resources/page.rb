class Mill

  class Resource

    class Page < Resource

      attr_accessor :title
      attr_accessor :body

      def self.resource_type
        :page
      end

      def self.import_types
        [:html, :markdown]
      end

      def self.root_elem_name
        'page'
      end

      def self.root_attribute_names
        super + %w{title}
      end

      def import(file)
        super
        if FileTypeMapper.extensions_for_type(:markdown).include?(file.extname)
          import_markdown(file)
        elsif FileTypeMapper.extensions_for_type(:html).include?(file.extname)
          import_html(file)
        else
          raise "Can't import file #{file}"
        end
        @path = @path.replace_extension('.html')
      end

      def import_html(file)
        html = Nokogiri::HTML(file.read) { |config| config.strict }
        html.errors.reject { |e| e.message =~ /Tag members? invalid/ }.each do |error|
          log.error { "#{file}: Error in HTML: #{error.line}:#{error.column}: #{error.message}" }
        end
        @title = html.at_xpath('/html/head/title').text
        html.xpath('/html/head/meta[@name]').each do |meta_elem|
          name, content = meta_elem['name'], meta_elem['content']
          send("#{name}=", content)
        end
        @body = html.at_xpath('/html/body').children.to_xhtml
      end

      def import_markdown(file)
        text = parse_markdown(file.read)
        @body = Nokogiri::HTML(Kramdown::Document.new(text).to_html).at_xpath('/html/body').children.to_xhtml
      end

      def parse_markdown(text)
        parse_markdown_header(text)
      end

      def parse_markdown_header(text)
        if text =~ /^\w+:\s+/
          header, text = text.split(/\n\n/, 2)
          header.split(/\n/).each do |line|
            key, value = line.strip.split(/:\s+/)
            key = key.gsub('-', '_').downcase.to_sym
            send("#{key}=", value)
          end
        end
        text
      end

      def load(root_elem)
        super
        @body = root_elem.children
      end

      def root_elem_content
        @body
      end

      def render(output_dir: nil)
        dest_file = dest_file(output_dir)
        dest_file.dirname.mkpath unless dest_file.dirname.exist?
        log.debug(2) { "rendering HTML to #{dest_file}" }
        dest_file.open('w') { |io| io.write(to_html) }
        dest_file
      end

      def to_html
        builder = Nokogiri::HTML::Builder.new(encoding: 'utf-8') do |builder|
          builder.html do
            builder.head do
              builder.meta(name: 'date', content: @date) if @date
              builder.title(@title) if @title
            end
            builder.body do
              builder << @body.to_html if @body
            end
          end
        end
        @html = builder.doc
        decorate
        @html
      end

      def decorate
        # implemented by subclass
      end

      def add_image_sizes
        log.debug(3) { "adding image sizes" }
        @html.xpath('//img').each do |img|
          img_link = Addressable::URI.parse(img['src'])
          next if img_link.host
          img_path = Path.new((Addressable::URI.parse(path.to_s) + img_link).path)
          log.debug(4) { "adding image size to #{img_path}" }
          img_resource = @mill[img_path]
          img[:width], img[:height] = img_resource.width, img_resource.height
        end
      end

      def add_external_link_targets
        log.debug(3) { "adding link targets" }
        @html.xpath('//a').each do |a|
          if a['href'] && a['href'] =~ /^\w+:/
            log.debug(4) { "#{a['href']}" }
            a['target'] = '_blank'
          end
        end
      end

      def add_script(script)
        if script.kind_of?(Hash)
          elem = @html.create_element('script', script)
        else
          elem = @html.create_element('script') { |e| e.content = script }
        end
        @html.at_xpath('/html/head') << elem
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
        elem = @html.create_element('link', attrs) { e.content = yield if block_given? }
        @html.at_xpath('/html/head') << elem
      end

      def set_title(title)
        title_elem = @html.at_xpath('/html/head/title')
        title_elem.content = title
      end

      def wrap_body(&block)
        body = @html.at_xpath('/html/body')
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
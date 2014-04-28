module Mill

  class Resource

    attr_accessor :src_file
    attr_accessor :dest_file
    attr_accessor :date
    attr_accessor :title
    attr_accessor :status
    attr_accessor :data
    attr_accessor :site

    def initialize(params={})
      @status = []
      params.each { |k, v| send("#{k}=", v) }
    end

    def inspect
      "<#{self.class}: src_file: #{@src_file.to_s.inspect}, dest_file: #{@dest_file.to_s.inspect}, uri: #{uri.to_s.inspect}, date: #{@date.inspect}, title: #{@title.inspect}, status: #{@status.inspect}, data: <#{@data.class}>>"
    end

    def date=(date)
      @date = date.kind_of?(DateTime) ? date : DateTime.parse(date.to_s)
    end

    def status=(status)
      @status = status.kind_of?(Array) ? status : status.to_s.split(/\s/).map(&:downcase).map(&:to_sym)
    end

    def uri
      URI.parse('/' + @dest_file.relative_path_from(@site.site_dir).to_s)
    end

    def draft?
      @status.include?(:draft)
    end

    def invisible?
      @status.include?(:invisible)
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

    def wrap_body
      body = @data.at_xpath('/html/body')
      old_body = body.children.remove
      new_body = Nokogiri::XML::DocumentFragment.parse('')
      Nokogiri::HTML::Builder.with(new_body) do |builder|
        yield(self, builder, old_body)
      end
      body << new_body
    end

  end

end
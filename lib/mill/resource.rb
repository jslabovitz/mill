class Mill

  class Resource

    attr_accessor :input_file
    attr_accessor :output_file
    attr_accessor :date
    attr_accessor :public
    attr_accessor :content
    attr_accessor :mill

    def self.file_extensions
      # implemented in subclass
      []
    end

    def initialize(params={})
      @date = DateTime.now
      params.each { |k, v| send("#{k}=", v) }
    end

    def input_file=(p)
      @input_file = Path.new(p)
    end

    def output_file=(p)
      @output_file = Path.new(p)
    end

    def date=(x)
      @date = case x
      when String
        DateTime.parse(x)
      when Time
        DateTime.parse(x.to_s)
      when DateTime
        x
      else
        raise "Can't assign date: #{x.inspect}"
      end
    end

    def public=(x)
      @public = case x
      when 'false', FalseClass
        false
      when 'true', TrueClass
        true
      else
        raise "Can't assign public: #{x.inspect}"
      end
    end

    def uri
      raise "#{@input_file}: No output file defined for #{self.class}" unless @output_file
      path = '/' + @output_file.relative_to(@mill.output_dir).to_s
      path.sub!(%r{/index\.html$}, '/')
      path.sub!(%r{\.html$}, '') if @mill.shorten_uris
      Addressable::URI.parse(path)
    end

    def absolute_uri
      @mill.site_uri + uri
    end

    def tag_uri
      @mill.tag_uri + uri
    end

    def change_frequency
      :weekly
    end

    def load
      # implemented by subclass
    end

    def load_date
      @date = DateTime.parse(@input_file.mtime.to_s) if @input_file
    end

    def process
      # implemented in subclass
    end

    def render_content
      @content.to_s
    end

    def build
      @output_file.dirname.mkpath
      if @content
        content_str = render_content
        # ;;warn "#{uri}: writing content #{(@content_str[0..20] + '...').inspect} to #{@output_file}"
        @output_file.write(content_str)
      else
        # ;;warn "#{uri}: copying file #{@input_file} to #{@output_file}"
        @input_file.copy(@output_file)
      end
    end

  end

end
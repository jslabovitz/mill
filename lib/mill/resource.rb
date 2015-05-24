class Mill

  class Resource

    attr_accessor :input_file
    attr_accessor :output_file
    attr_accessor :date
    attr_accessor :public
    attr_accessor :content
    attr_accessor :mill
    attr_accessor :processed

    def self.default_params
      {}
    end

    def initialize(params={})
      self.class.default_params.merge(params).each { |k, v| send("#{k}=", v) }
      load
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

    def final_content
      @content
    end

    def load
      @mill.add_resource(self)
    end

    def process
      @processed = true
    end

    def build
      @output_file.dirname.mkpath
      if (c = final_content)
        @output_file.write(c.to_s)
      elsif @input_file
        # ;;warn "#{uri}: copying file #{@input_file} to #{@output_file}"
        @input_file.copy(@output_file)
      else
        raise "Can't build resource without content or input file: #{uri}"
      end
      verify
    end

    def verify
      # implemented in subclass
    end

  end

end
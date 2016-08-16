module Mill

  class Resource

    attr_accessor :input_file
    attr_accessor :output_file
    attr_accessor :date
    attr_accessor :public
    attr_accessor :content
    attr_accessor :site

    def self.type
      # implemented by subclass
    end

    def initialize(params={})
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
      when Date, DateTime
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
      path = '/' + @output_file.relative_to(@site.output_dir).to_s
      path.sub!(%r{/index\.html$}, '/')
      path.sub!(%r{\.html$}, '') if @site.shorten_uris
      Addressable::URI.parse(path)
    end

    def absolute_uri
      @site.site_uri + uri
    end

    def tag_uri
      @site.tag_uri + uri
    end

    def change_frequency
      :weekly
    end

    def load
      self.date ||= @input_file ? @input_file.mtime : DateTime.now
    end

    def build
      # implemented in subclass
    end

    def save
      @output_file.dirname.mkpath
      if @content
        # ;;warn "#{uri}: writing #{@input_file} to #{@output_file}"
        @output_file.write(@content.to_s)
        @output_file.utime(@date.to_time, @date.to_time)
      elsif @input_file
        # ;;warn "#{uri}: copying #{@input_file} to #{@output_file}"
        @input_file.copy(@output_file)
      else
        raise "Can't build resource without content or input file: #{uri}"
      end
    end

  end

end
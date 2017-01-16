module Mill

  class Resource

    FileTypes = []

    attr_accessor :input_file
    attr_accessor :output_file
    attr_accessor :date
    attr_accessor :public
    attr_accessor :content
    attr_accessor :site

    def initialize(input_file: nil,
                   output_file: nil,
                   date: nil,
                   public: false,
                   content: nil,
                   site: nil)
      @input_file = Path.new(input_file) if input_file
      @output_file = Path.new(output_file) if output_file
      self.date = date
      self.public = public
      @content = content
      @site = site
    end

    def date=(date)
      @date = case date
      when String, Time
        DateTime.parse(date.to_s)
      when Date, DateTime, nil
        date
      else
        raise Error, "Can't assign 'date' attribute: #{date.inspect}"
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

    def uri
      raise Error, "#{@input_file}: No output file defined for #{self.class}" unless @output_file
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
        raise Error, "Can't build resource without content or input file: #{uri}"
      end
    end

  end

end
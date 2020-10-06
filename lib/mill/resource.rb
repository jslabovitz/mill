module Mill

  class Resource

    FileTypes = []

    attr_accessor :input_file
    attr_accessor :output_file
    attr_accessor :path
    attr_accessor :date
    attr_accessor :public
    attr_accessor :content
    attr_accessor :site
    attr_accessor :node

    def initialize(input_file: nil,
                   output_file: nil,
                   date: nil,
                   public: false,
                   content: nil,
                   site: nil)
      if input_file
        @input_file = Path.new(input_file)
        @date = input_file.mtime.to_datetime
      else
        @date = DateTime.now
      end
      @output_file = Path.new(output_file) if output_file
      @path = '/' + @output_file.relative_to(site.output_dir).to_s
      self.date = date if date
      self.public = public
      @content = content
      @site = site
    end

    def date=(date)
      @date = case date
      when String, Time
        begin
          DateTime.parse(date.to_s)
        rescue ArgumentError => e
          raise Error, "Can't parse date: #{date.inspect}"
        end
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

    def public?
      @public == true
    end

    def text?
      kind_of?(Resource::Text) && public?
    end

    def redirect?
      kind_of?(Resource::Redirect)
    end

    def inspect
      "<%p> input_file: %p, output_file: %p, path: %s, date: %s, public: %p, content: <%p>, parent: %p, siblings: %p, children: %p" % [
        self.class,
        @input_file ? @input_file.relative_to(@site.input_dir).to_s : nil,
        @output_file ? @output_file.relative_to(@site.output_dir).to_s : nil,
        @path,
        @date.to_s,
        @public,
        @content&.class,
        parent&.path,
        siblings.map(&:path),
        children.map(&:path),
      ]
    end

    def parent
      @node.parent&.content
    end

    def siblings
      @node.siblings.map(&:content).compact
    end

    def children
      @node.children.map(&:content).compact
    end

    def uri
      raise Error, "#{@input_file}: No path defined for #{self.class}" unless @path
      Addressable::URI.encode(@path, Addressable::URI)
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

    def final_content
      @content
    end

    def load
      # implemented in subclass
    end

    def build
      # implemented in subclass
    end

    def save
      @output_file.dirname.mkpath
      if (content = final_content)
        # ;;warn "#{path}: writing #{@input_file} to #{@output_file}"
        @output_file.write(content.to_s)
        @output_file.utime(@date.to_time, @date.to_time)
      elsif @input_file
        # ;;warn "#{path}: copying #{@input_file} to #{@output_file}"
        @input_file.copy(@output_file)
      else
        raise Error, "Can't build resource without content or input file: #{path}"
      end
    end

  end

end
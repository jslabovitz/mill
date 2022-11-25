module Mill

  class Resource

    FileTypes = []
    ListKeys = {
      path:         nil,
      input_file:   nil,
      output_file:  nil,
      date:         nil,
      publish?:     nil,
      advertise?:   nil,
      class:        nil,
      content:      proc { |v| v ? ('%s (%dKB)' % [v.class, (v.to_s.length / 1024.0).ceil]) : nil },
      parent:       proc { |v| v&.path },
      siblings:     proc { |v| v&.map(&:path) },
      children:     proc { |v| v&.map(&:path) },
    }
    ListKeyWidth = ListKeys.keys.map(&:length).max

    attr_accessor :path
    attr_reader   :uri
    attr_accessor :input_file
    attr_reader   :date
    attr_accessor :content
    attr_accessor :site
    attr_accessor :node

    include SetParams

    def initialize(params={})
      super
      @date = (@input_file ? @input_file.mtime.to_datetime : DateTime.now) unless defined?(@date)
      @uri = Addressable::URI.encode(@path, Addressable::URI)
    end

    def date=(date)
      @date = case date
      when String
        begin
          DateTime.parse(date.to_s)
        rescue ArgumentError => e
          raise Error, "Can't parse date: #{date.inspect} (#{e})"
        end
      when Time, Date
        date.to_datetime
      when DateTime, nil
        date
      else
        raise Error, "Can't assign 'date' attribute: #{date.inspect}"
      end
    end

    def publish?
      true
    end

    def advertise?
      false
    end

    def root?
      self == @site.home_resource
    end

    def output_file
      if @site && @path
        @site.output_dir / Path.new(@path).relative_to('/')
      else
        nil
      end
    end

    def inspect
      "<%p> path: %p, input_file: %p, output_file: %p, date: %s, publish: %p, advertise: %p, content: <%p>, parent: %p, siblings: %p, children: %p" % [
        self.class,
        @path,
        @input_file ? @input_file.relative_to(@site.input_dir).to_s : nil,
        (o = output_file) ? o.relative_to(@site.output_dir).to_s : nil,
        @date.to_s,
        publish?,
        advertise?,
        @content&.class,
        @node && parent&.path,
        @node && siblings&.map(&:path),
        @node && children&.map(&:path),
      ]
    end

    def list
      ListKeys.keys.each { |k| list_key(k) }
      puts
    end

    def list_key(key)
      print '%*s: ' % [ListKeyWidth, key]
      value = send(key)
      value = (converter = ListKeys[key]) ? converter.call(value) : value
      case value
      when Array
        if value.empty?
          puts '-'
        else
          value.each_with_index do |v, i|
            print '%*s  ' % [ListKeyWidth, ''] if i > 0
            puts (v.nil? ? '-' : v)
          end
        end
      else
        puts (value.nil? ? '-' : value)
      end
    end

    def parent
      @node&.parent&.content
    end

    def siblings
      @node && @node.siblings.map(&:content).compact
    end

    def children
      @node && @node.children.map(&:content).compact
    end

    def absolute_uri
      @site.site_uri + @uri
    end

    def tag_uri
      @site.tag_uri + @uri
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
      file = output_file
      file.dirname.mkpath
      if (content = final_content)
        # ;;warn "#{@path}: writing #{@input_file} to #{file}"
        file.write(content.to_s)
        file.utime(@date.to_time, @date.to_time)
      elsif @input_file
        # ;;warn "#{@path}: copying #{@input_file} to #{file}"
        @input_file.copy(file)
      else
        raise Error, "#{@path}: Can't build resource without content or input file"
      end
    end

  end

end
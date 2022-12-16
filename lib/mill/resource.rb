module Mill

  class Resource

    FileTypes = []
    ListKeys = {
      path:         nil,
      input:        nil,
      output_file:  nil,
      date:         nil,
      advertise?:   nil,
      class:        nil,
      parent:       proc { |v| v&.path },
      siblings:     proc { |v| v&.map(&:path) },
      children:     proc { |v| v&.map(&:path) },
    }
    ListKeyWidth = ListKeys.keys.map(&:length).max

    attr_accessor :path
    attr_reader   :uri
    attr_accessor :input
    attr_reader   :date
    attr_reader   :output
    attr_accessor :site
    attr_accessor :node

    include SetParams

    def initialize(params={})
      super
      unless defined?(@date)
        @date = @input&.kind_of?(Path) ? @input.mtime.to_datetime : DateTime.now
      end
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

    def advertise?
      false
    end

    def root?
      self == @site.root_resource
    end

    def output_file
      if @site && @path
        @site.output_dir / Path.new(@path).relative_to('/')
      else
        nil
      end
    end

    def inspect
      "<%p> path: %p, input: %p, output_file: %p, date: %s, advertise: %p, parent: %p, siblings: %p, children: %p" % [
        self.class,
        @path,
        case @input
        when Path
          @input.relative_to(@site.input_dir).to_s
        when String
          @input[0..9].inspect
        else
          "<#{@input.class}>"
        end,
        (o = output_file) ? o.relative_to(@site.output_dir).to_s : nil,
        @date.to_s,
        advertise?,
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

    def previous_sibling
      @node.previous_sibling&.content
    end

    def next_sibling
      @node.next_sibling&.content
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

    def load
      # implemented in subclass
    end

    def build
      # implemented in subclass
    end

    def save
      file = output_file
      file.dirname.mkpath
      if @output
        # ;;warn "#{@path}: writing output to #{file}"
        file.write(@output)
        file.utime(@date.to_time, @date.to_time)
      elsif @input.kind_of?(Path)
        # ;;warn "#{@path}: copying #{@input} to #{file}"
        @input.copy(file)
      elsif @input
        # ;;warn "#{@path}: writing input to #{file}"
        file.write(@input)
        file.utime(@date.to_time, @date.to_time)
      else
        raise Error, "#{@path}: Can't build resource without output or input file"
      end
    end

  end

end
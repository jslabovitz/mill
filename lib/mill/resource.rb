module Mill

  class Resource

    FileTypes = []

    attr_accessor :path
    attr_accessor :uri
    attr_accessor :primary
    attr_accessor :input
    attr_accessor :date
    attr_reader   :output
    attr_accessor :site
    attr_accessor :node

    include SetParams
    include Simple::Printer::Printable

    def initialize(params={})
      super({ primary: false }.merge(params))
      unless defined?(@date)
        @date = @input&.kind_of?(Path) ? @input.mtime.to_datetime : DateTime.now
      end
      @uri = Addressable::URI.encode(@path, Addressable::URI)
    end

    def inspect
      "<#{self.class}>"
    end

    def primary?
      @primary
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

    def printable
      [
        :path,
        { key: :input, value: input_description },
        { key: :output_file, value: (o = output_file) ? o.relative_to(@site.output_dir).to_s : nil },
        :date,
        :primary?,
        :class,
        { label: 'Parent', value: parent&.path || '-' },
        { label: 'Siblings', value: siblings&.map(&:path)&.join(', ') || '-' },
        { label: 'Children', value: children&.map(&:path)&.join(', ') || '-' },
      ]
    end

    def input_description
      case @input
      when Path
        @input.relative_to(@site.input_dir).to_s
      when String
        (@input[0...100] + '...').inspect
      when nil
        '-'
      else
        "<#{@input.class}>"
      end
    end

    def parent
      @node&.parent&.content
    end

    def siblings
      @node ? @node.siblings.map(&:content).compact : []
    end

    def previous_sibling
      @node&.previous_sibling&.content
    end

    def next_sibling
      @node&.next_sibling&.content
    end

    def children
      @node ? @node.children.map(&:content).compact : []
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
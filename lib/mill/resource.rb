class Mill

  class Resource

    attr_accessor :src_path
    attr_accessor :path
    attr_accessor :type
    attr_accessor :title
    attr_accessor :date
    attr_accessor :data
    attr_accessor :processor

    def self.load_file(file, processor)
      resource = new(
        src_path: file,
        path: file.relative_to(processor.src_dir).without_extension,
        type: Mill.type_for_file(file),
        processor: processor)
      [resource]
    end

    def self.load_path(path, processor, type=nil)
      path = Path.new(path)
      if path.extname.empty?
        files = processor.src_dir.glob(path.relative_to('/').to_s + '.*')
        resources = files.map do |file|
          load_file(file, processor)
        end.flatten
        resources.select! { |r| r.type == type } if type
        raise "No resources for path #{path} (type = #{type.inspect}) in #{processor.src_dir}" if resources.empty?
        resources
      else
        file = processor.dest_dir / Path.new(path).relative_to('/')
        if type
          extensions = Mill.extensions_for_type(type) or raise "Unknown file type: #{type.inspect}"
          file.add_extension(extensions.first)
        end
        load_file(file, processor)
      end
    end

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
    end

    def inspect
      "<#{self.class}: " + instance_variables.map do |var|
        val = instance_variable_get(var)
        str = case var
        when :@data, :@processor
          "<#{val.class}>"
        when :@date, :@src_path, :@path
          val.to_s
        when :@log
          nil
        else
          val.inspect
        end
        "#{var[1..-1]} = #{str}" if str
      end.compact.join(', ') + '>'
    end

    def dest_path
      @processor.dest_dir / (@path.to_s + Mill.extensions_for_type(@type).first)
    end

    def uri
      Addressable::URI.parse('/' + @path.to_s)
    end

    def uri_with_extension
      Addressable::URI.parse('/' + @path.to_s + Mill.extensions_for_type(@type).first)
    end

    def date=(date)
      @date = date.kind_of?(DateTime) ? date : DateTime.parse(date)
    end

    def load
      load_file_metadata
    end

    def process
    end

    def save
      if @data
        write_file
      else
        copy_file
      end
    end

    def load_file_metadata
      @date ||= @src_path.mtime
    end

    def read_file
      log.debug(3) { "reading file #{@src_path.to_s.inspect}" }
      @data ||= @src_path.read
    end

    def write_file
      log.debug(3) { "writing file #{dest_path}" }
      dest_path.dirname.mkpath unless dest_path.dirname.exist?
      dest_path.open('w') { |io| io.write(@data) }
      dest_path.utime(@date.to_time, @date.to_time)
    end

    def copy_file
      log.debug(3) { "copying file #{@src_path} to #{dest_path}" }
      dest_path.dirname.mkpath unless dest_path.dirname.exist?
      @src_path.cp(dest_path)
    end

  end

end
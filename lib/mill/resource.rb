class Mill

  class Resource

    class SkipResource < Exception; end

    attr_accessor :src_path
    attr_accessor :path
    attr_accessor :type
    attr_accessor :title
    attr_accessor :date
    attr_accessor :data
    attr_accessor :processor

    def self.load_file(file, processor)
      begin
        resource = new(
          src_path: file,
          path: Path.new('/') / file.relative_to(processor.src_dir).without_extension,
          type: Mill.type_for_file(file),
          processor: processor)
        [resource]
      rescue SkipResource
        []
      end
    end

    def self.load_path(path, processor, type=nil)
      path = Path.new(path)
      if path.extname.empty?
        pattern = path.relative_to('/').add_extension('.*')
        files = processor.src_dir.glob(pattern)
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
      @date = DateTime.now
      params.each { |k, v| send("#{k}=", v) }
      load
    end

    def inspect
      "<#{self.class}[#{'0x%08x' % self.object_id}]: " + instance_variables.map do |var|
        val = instance_variable_get(var)
        str = case var
        when :@data
          "<#{val.class}>"
        else
          case val
          when Logger, Processor
            "<#{val.class}>"
          when DateTime, Time, Path
            val.to_s
          else
            val.inspect
          end
        end
        "#{var[1..-1]} = #{str}"
      end.join(', ') + '>'
    end

    def dest_path
      @processor.dest_dir / (@path.relative_to('/').to_s + Mill.extensions_for_type(@type).first)
    end

    def uri
      Addressable::URI.parse(@path.to_s)
    end

    def uri_with_extension
      Addressable::URI.parse(@path.add_extension(Mill.extensions_for_type(@type).first).to_s)
    end

    def date=(date)
      @date = date.kind_of?(DateTime) ? date : DateTime.parse(date)
    end

    def full_title
      @title
    end

    def load
      raise "Already loaded!" if @loaded
      @loaded = true
      load_file_metadata
    end

    def process
    end

    def save
      if @data
        write_file
      elsif @src_path
        copy_file
      end
    end

    def load_file_metadata
      @date ||= @src_path.mtime.to_datetime
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
class Mill

  class Resource

    class SkipResource < Exception; end

    attr_accessor :mill
    attr_accessor :file
    attr_accessor :path
    attr_accessor :date

    @@resource_classes = []

    def self.inherited(subclass)
      @@resource_classes << subclass
    end

    def self.resource_class_for_type(type)
      unless defined?(@@resource_class_map)
        @@resource_class_map = {}
        @@resource_classes.each do |resource_class|
          @@resource_class_map[resource_class.resource_type] = resource_class
        end
      end
      @@resource_class_map[type]
    end

    def self.load(file, params={})
      file = file.add_extension('.xml') unless file.exist?
      raise "No resource: #{file}" unless file.exist?
      xml = Nokogiri::XML(file.read)
      root_elem = xml.root
      resource_type = root_elem.name.to_sym
      resource_class = resource_class_for_type(resource_type) \
        or raise "Can't find resource class for #{resource_type.inspect}"
      resource = resource_class.new(params)
      resource.load(root_elem)
      resource
    end

    def self.import(file, params={})
      resource = new(params)
      resource.import(file)
      resource
    end

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
    end

    def date=(date)
      @date = date.kind_of?(DateTime) ? date : DateTime.parse(date)
    end

    def inspect
      "<#{self.class}[#{'0x%08x' % self.object_id}]: " + instance_variables.map do |var|
        val = instance_variable_get(var)
        str = case val
        when DateTime, Time
          val.to_s
        when Path
          val.to_s.inspect
        when Nokogiri::XML::Document, Nokogiri::XML::NodeSet
          (val.to_xml[0..20] + '...').inspect
        when Numeric, String, Symbol
          val.inspect
        else
          "<#{val.class}>"
        end
        "#{var[1..-1]}=#{str}"
      end.join(', ') + '>'
    end

    def import(file)
      @date = file.mtime.to_datetime
    end

    def load(root_elem, &block)
      @path = Path.new(root_elem['path'])
      @date = DateTime.parse(root_elem['date'])
      yield(root_elem) if block_given?
    end

    def save(dir)
      file = dir / @path.relative_to('/').add_extension('.xml')
      log.debug(3) { "saving resource to #{file.to_s.inspect}" }
      raise "resource already exists at #{file.to_s.inspect}" if file.exist?
      file.dirname.mkpath unless file.dirname.exist?
      file.open('w') { |io| io.write(to_xml) }
      file.utime(@date.to_time, @date.to_time) if @date
    end

    def to_xml(&block)
      builder = Nokogiri::XML::Builder.new do |builder|
        yield(builder) if block_given?
      end
      builder.doc
    end

    def root_attributes
      {
        path: @path,
        date: @date
      }
    end

    def dest_file(dir, type)
      dir / (@path.relative_to('/').to_s + FileTypeMapper.extensions_for_type(type).first)
    end

    def uri
      Addressable::URI.parse(@path.to_s)
    end

    def uri_with_extension(extension=nil)
      extension ||= FileTypeMapper.extensions_for_type(self.class.resource_type).first
      Addressable::URI.parse(@path.add_extension(extension).to_s)
    end

  end

end
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

    def self.build_resource_maps
      @@resource_type_map = {}
      @@resource_import_map = {}
      @@resource_classes.each do |resource_class|
        @@resource_type_map[resource_class.resource_type] = resource_class
        resource_class.import_types.each do |type|
          FileTypeMapper.extensions_for_type(type).each do |extname|
            @@resource_import_map[extname] = resource_class
          end
        end
      end
    end

    def self.resource_class_for_type(type)
      build_resource_maps unless defined?(@@resource_class_map)
      @@resource_type_map[type]
    end

    def self.resource_class_for_import_type(type)
      build_resource_maps unless defined?(@@resource_import_map)
      @@resource_import_map[type]
    end

    def self.root_elem_name
      # implemented by subclass
    end

    def self.root_attribute_names
      %w{path date}
      # additional implemented by subclass
    end

    def self.load(file, params={})
      file = file.add_extension('.xml') unless file.exist?
      raise "No resource: #{file}" unless file.exist?
      xml = Nokogiri::XML(file.read)
      root_elem = xml.root or raise "No root in XML file: #{file}"
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

    def path=(path)
      @path = Path.new(path)
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
        when Numeric, Symbol
          val.inspect
        when String
          if val.length > 20
            val[0..20].inspect + '...'
          else
            val.inspect
          end
        else
          "<#{val.class}>"
        end
        "#{var[1..-1]}=#{str}"
      end.join(', ') + '>'
    end

    def import(file)
      @date = file.mtime.to_datetime
    end

    def load(root_elem)
      self.class.root_attribute_names.each do |key|
        send("#{key}=", root_elem[key])
      end
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
      xml = Nokogiri::XML::Document.new
      root_elem = xml.create_element(self.class.root_elem_name, root_attributes)
      xml << root_elem
      root_elem << root_elem_content if root_elem_content
      xml
    end

    def root_elem_content
      # implemented by subclass
    end

    def root_attributes
      Hash[
        self.class.root_attribute_names.map { |name| [name, send(name)] }
      ]
    end

    def dest_file(dir)
      dir / @path.relative_to('/')
    end

  end

end
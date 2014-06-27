class Mill

  class Importer

    attr_accessor :input_dir
    attr_accessor :output_dir

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
    end

    def input_dir=(dir)
      @input_dir = Path.new(dir)
    end

    def output_dir=(dir)
      @output_dir = Path.new(dir)
    end

    def import
      @input_dir.find do |file|
        next if file.hidden? || file.directory?
        log.debug(2) { "importing file #{file}" }
        resource = resource_for_file(file) or raise "#{file}: Unknown resource type"
        # ;;puts '', "--- #{file}", resource.xml.to_s
        log.debug(3) { "loaded resource: #{resource.inspect}" }
        resource.save(@output_dir)
      end
    end

    def resource_for_file(file)
      resource_class = Resource.resource_class_for_import_type(file.extname) || Resource.resource_class_for_import_type('*')
      path = Path.new('/') / file.relative_to(@input_dir)
      resource_class.import(file, path: path)
    end

  end

end
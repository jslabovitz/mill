class Mill

  class Importer

    attr_accessor :input_dir
    attr_accessor :output_dir

    HandlersMap = {
      html:     Mill::Resource::Page,
      markdown: Mill::Resource::Page,
      image:    Mill::Resource::Image,
      any:      Mill::Resource::File,
    }

    def initialize(params={})
      build_handlers
      params.each { |k, v| send("#{k}=", v) }
    end

    def input_dir=(dir)
      @input_dir = Path.new(dir)
    end

    def output_dir=(dir)
      @output_dir = Path.new(dir)
    end

    def build_handlers
      @handlers = {}
      HandlersMap.each do |type, resource_class|
        FileTypeMapper.extensions_for_type(type).each do |extname|
          @handlers[extname] = resource_class
        end
      end
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
      resource_class = @handlers[file.extname] || @handlers['*']
      path = Path.new('/') / file.relative_to(@input_dir).without_extension
      resource_class.import(file, path: path)
    end

  end

end
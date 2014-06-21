class Mill

  class Processor

    attr_accessor :name
    attr_accessor :mill
    attr_accessor :src_dir
    attr_accessor :dest_dir
    attr_accessor :handlers
    attr_accessor :resources

    def initialize(params={})
      @handlers = {}
      @resources = []
      params.each { |k, v| send("#{k}=", v) }
    end

    def input(dir)
      @src_dir = Path.new(dir)
    end

    def output(dir)
      @dest_dir = Path.new(dir)
    end

    def process(type, resource_class)
      Mill.extensions_for_type(type).each do |type|
        @handlers[type] = resource_class
      end
    end

    def clean
      @dest_dir.rmtree if @dest_dir.exist?
    end

    def build
      log.debug "#{@name}: building from #{@src_dir} to #{@dest_dir} for #{@handlers.keys.inspect}"
      load_resources
      mill.resources_loaded(self)
      process_resources
    end

    def load_resources
      return unless @src_dir && @src_dir.exist?
      log.debug(1) { "loading files from #{@src_dir}" }
      @src_dir.find do |file|
        next if file.hidden? || file.directory?
        log.debug(2) { "loading file #{file}" }
        @handlers.each do |extname, resource_class|
          if extname == '*' || file.extname == extname
            resource_class.load_file(file, self).each do |resource|
              log.debug(3) { "loaded resource: #{resource.inspect}" }
              @resources << resource
            end
            break
          end
        end
      end
    end

    def generate(resource_class, params={})
      @resources << resource_class.new(params)
    end

    def process_resources
      log.debug(1) { "processing resources"}
      @resources.each do |resource|
        log.debug(2) { "processing resource #{resource.inspect}" }
        resource.process
        log.debug(2) { "saving resource #{resource.inspect}" }
        resource.save
      end
    end

  end

end
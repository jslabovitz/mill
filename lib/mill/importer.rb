class Mill

  class Importer

    attr_accessor :input_file
    attr_accessor :output_file
    attr_accessor :metadata
    attr_accessor :content
    attr_accessor :mill

    def initialize(params={})
      @metadata = {
        date: DateTime.now,
      }
      params.each { |k, v| send("#{k}=", v) }
    end

    def resource_class
      @mill.resource_class_for_file(@output_file)
    end

    def import
      process
      make_resource
    end

    def process
      # implemented by subclass
    end

    def make_resource
      resource = resource_class.new(
        @metadata.merge(
          {
            input_file: @input_file,
            output_file: @output_file,
            content: @content,
            mill: @mill,
          }
        )
      )
      resource.load
    end

  end

end
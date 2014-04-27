module Mill

  class Resource

    attr_accessor :src_file
    attr_accessor :dest_file
    attr_accessor :date
    attr_accessor :title
    attr_accessor :status
    attr_accessor :data
    attr_accessor :site

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
    end

    def inspect
      "<#{self.class}: src_file: #{@src_file.to_s.inspect}, dest_file: #{@dest_file.to_s.inspect}, uri: #{uri.to_s.inspect}, date: #{@date.inspect}, title: #{@title.inspect}, data: <#{@data.class}>>"
    end

    def uri
      URI.parse('/' + @dest_file.relative_path_from(@site.site_dir).to_s)
    end

  end

end
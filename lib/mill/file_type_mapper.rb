class Mill

  module FileTypeMapper

    FileTypes = {
      any:      '*',
      image:    [:jpeg, :tiff, :png, :ico, :gif],
      png:      '.png',
      ico:      '.ico',
      gif:      '.gif',
      jpeg:     %w{.jpg .jpeg},
      tiff:     %w{.tif .tiff},
      yaml:     '.yaml',
      html:     '.html',
      css:      '.css',
      js:       '.js',
      pdf:      '.pdf',
      markdown: %w{.md .mdown .markdown},
    }

    @extensions_for_type = nil
    @type_for_extension = nil

    def self.lookup_type(type)
      case type
      when Symbol
        lookup_type(FileTypes[type])
      when String
        type
      when Array
        type.map { |t| lookup_type(t) }.flatten
      else
        raise "Unknown type: #{type.inspect}"
      end
    end

    def self.build_tables
      return if @extensions_for_type
      @extensions_for_type = {}
      @type_for_extension = {}
      FileTypes.keys.each do |type|
        extensions = [lookup_type(type)].flatten
        @extensions_for_type[type] = extensions
        extensions.each do |extension|
          @type_for_extension[extension] = type
        end
      end
    end

    def self.extensions_for_type(type)
      build_tables
      @extensions_for_type[type] or raise "Can't determine extensions for type #{type.inspect}"
    end

    def self.type_for_file(file)
      build_tables
      @type_for_extension[file.extname] or raise "Can't determine type for file #{file} (#{file.extname} =~ #{@type_for_extension.inspect}"
    end

  end

end
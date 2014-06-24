class Mill

  class Resource

    class File < Resource

      attr_accessor :source

      def self.resource_type
        :file
      end

      def import(file)
        super
        @source = file
        @file_type = FileTypeMapper.type_for_file(file)
      end

      def load(root_elem)
        super do |root_elem|
          @source = Path.new(root_elem['source'])
          @file_type = root_elem['type'].to_sym
        end
      end

      def root_attributes
        super.merge(
          source: @source,
          type: @file_type,
        )
      end

      def to_xml
        super do |builder|
          builder.file(root_attributes)
        end
      end

      def render(output_dir: nil)
        dest_file = dest_file(output_dir, @file_type)
        dest_file.dirname.mkpath unless dest_file.dirname.exist?
        log.debug(2) { "rendering file #{@source} to #{dest_file}" }
        @source.cp(dest_file)
        dest_file
      end

    end

  end

end
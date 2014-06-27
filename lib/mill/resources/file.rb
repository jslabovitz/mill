class Mill

  class Resource

    class File < Resource

      attr_accessor :source

      def self.resource_type
        :file
      end

      def self.import_types
        [:any]
      end

      def self.root_elem_name
        'file'
      end

      def self.root_attribute_names
        super + %w{source}
      end

      def source=(path)
        @source = Path.new(path)
      end

      def import(file)
        super
        self.source = file
      end

      def render(output_dir: nil)
        dest_file = dest_file(output_dir)
        dest_file.dirname.mkpath unless dest_file.dirname.exist?
        log.debug(2) { "copying #{@source} to #{dest_file}" }
        @source.cp(dest_file)
        dest_file
      end

    end

  end

end
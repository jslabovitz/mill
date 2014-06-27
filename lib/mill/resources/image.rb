class Mill

  class Resource

    class Image < File

      attr_accessor :width
      attr_accessor :height

      def self.resource_type
        :image
      end

      def self.import_types
        [:image]
      end

      def self.root_elem_name
        'image'
      end

      def self.root_attribute_names
        super + %w{width height}
      end

      def width=(n)
        @width = n.to_i
      end

      def height=(n)
        @height = n.to_i
      end

      def import(file)
        super
        info = ImageSize.path(file.to_s)
        @width, @height = *info.size
      end

    end

  end

end
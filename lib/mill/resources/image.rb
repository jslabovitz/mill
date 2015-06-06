class Mill

  class Resource

    class Image < Resource

      attr_accessor :width
      attr_accessor :height

      def self.type
        :image
      end

      def load
        info = ImageSize.path(@input_file.to_s)
        @width, @height = *info.size
        super
      end

    end

  end

end
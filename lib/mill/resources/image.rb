class Mill

  class Resource

    class Image < Resource

      attr_accessor :format
      attr_accessor :width
      attr_accessor :height

      def load
        super
        load_image_info
      end

      def load_image_info
        info = ImageSize.path(@src_file.to_s)
        @format = info.format
        @width, @height = info.size
      end

    end

  end

end
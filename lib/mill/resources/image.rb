class Mill

  class Resource

    class Image < Resource

      attr_accessor :width
      attr_accessor :height

      def self.file_extensions
        %w{
          .jpeg .jpg
          .gif
          .tiff .tif
          .png
        }
      end

      def load
        load_date
        info = ImageSize.path(@input_file.to_s)
        @width, @height = *info.size
      end

    end

  end

end
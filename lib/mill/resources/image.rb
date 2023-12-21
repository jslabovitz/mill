module Mill

  class Resource

    class Image < Resource

      FileTypes = %w{
        image/gif
        image/jpeg
        image/png
        image/tiff
        image/vnd.microsoft.icon
        image/svg+xml
      }

      attr_accessor :width
      attr_accessor :height

      def printable
        super + [
          :width,
          :height,
        ]
      end

      def load
        raise Error, "Input must be file" unless @input.kind_of?(Path)
        begin
          info = ImageSize.path(@input.to_s)
        rescue => e
          raise Error, "Can't load image file #{@input.to_s.inspect}: #{e}"
        end
        @width, @height = *info.size
      end

    end

  end

end
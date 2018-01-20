module Mill

  class Resource

    class Image < Resource

      include HTMLHelpers

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

      def inspect
        super + ", width: %p, height: %p" % [
          @width,
          @height,
        ]
      end

      def load
        info = ImageSize.path(@input_file.to_s)
        @width, @height = *info.size
        super
      end

      def img_html
        html_fragment do |html|
          html.img(
            src: uri,
            alt: @title,
            height: @height,
            width: @width)
        end
      end

    end

  end

end
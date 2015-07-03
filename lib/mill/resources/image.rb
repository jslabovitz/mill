class Mill

  class Resource

    class Image < Resource

      include HTMLHelpers

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
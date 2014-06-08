class TestMill < Mill

  class Resource

    class Image < Mill::Resource::Image

      Size = 500

      def process
        resize_image
        super
      end

      def resize_image
        src_image ||= Magick::Image.read(src_path.to_s).first
        log.debug(2) { "resizing image #{@src_path} to #{Size}px" }
        dest_image = src_image.dup
        dest_image.change_geometry!("#{Size}x#{Size}") { |cols, rows, img| img.resize!(cols, rows) }
        @data = dest_image.to_blob do
          self.format = 'JPEG'
          self.quality = 80
        end
        @type = :jpeg
      end

    end

  end

end
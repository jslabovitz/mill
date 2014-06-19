class TestMill < Mill

  class Resource

    class Image < Mill::Resource::Image

      def process
        resize_image(size: @processor.mill.max_image_size)
        super
      end

      def resize_image(size: nil, format: 'JPEG', type: :jpeg, quality: 80)
        src_image ||= Magick::Image.read(src_path.to_s).first
        log.debug(2) { "resizing image #{@src_path} to #{size}px" }
        dest_image = src_image.dup
        dest_image.change_geometry!("#{size}x#{size}") { |cols, rows, img| img.resize!(cols, rows) }
        @data = dest_image.to_blob do
          self.format = format
          self.quality = quality
        end
        @type = type
      end

    end

  end

end
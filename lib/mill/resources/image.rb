class Mill

  class Resource

    class Image < Resource

      attr_accessor :source
      attr_accessor :image_type
      attr_accessor :width
      attr_accessor :height

      def self.resource_type
        :image
      end

      def import(file)
        super
        info = ImageSize.path(file.to_s)
        @source = file
        @image_type = info.format
        @width, @height = *info.size
      end

      def load(resource_class)
        super do |root_elem|
          @source = Path.new(root_elem['source'])
          @image_type = root_elem['type'].to_sym
          @width = root_elem['width'].to_i
          @height = root_elem['height'].to_i
        end
      end

      def root_attributes
        super.merge(
          source: @source,
          type: @image_type,
          width: @width,
          height: @height,
        )
      end

      def to_xml
        super do |builder|
          builder.image(root_attributes)
        end
      end

      def render(output_dir: nil, size: nil, type: :jpeg, quality: 80)
        dest_file = dest_file(output_dir, type)
        dest_file.dirname.mkpath unless dest_file.dirname.exist?
        log.debug(2) { "rendering image #{@source} to #{dest_file}" }
        if @image_type != :jpeg || (size && (@width > size || @height > size))
          src_image ||= Magick::Image.read(@source.to_s).first
          dest_image = src_image.dup
          #FIXME: don't enlarge?
          if size
            dest_image.change_geometry!("#{size}x#{size}") { |cols, rows, img| img.resize!(cols, rows) }
          end
          dest_image.write(dest_file.to_s) do |img|
            img.quality = quality
          end
        else
          log.debug(3) { "copying image" }
          @source.cp(dest_file)
        end
        dest_file
      end

    end

  end

end
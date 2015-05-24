class Mill

  class Importers

    class Image < Importer

      def process
        info = ImageSize.path(@input_file.to_s)
        @metadata[:width], @metadata[:height] = *info.size
      end

    end

  end

end
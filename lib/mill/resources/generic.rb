class Mill

  class Resource

    class Generic < Resource

      def self.file_extensions
        %w{
          .pdf
          .otf .ttf
          .css
          .js
        }
      end

      def load
        load_date
      end

    end

  end

end
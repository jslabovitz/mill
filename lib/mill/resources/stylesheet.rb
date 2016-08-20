module Mill

  class Resource

    class Stylesheet < Resource

      FileTypes = %w{
        text/css
      }

      def build
        @content = CSSminify.compress(@input_file)
        if false
          original_size = @input_file.size
          minified_size = @content.length
          ;;warn "saved %d bytes (%.1f%%) by minifying CSS #{uri}" % [
            original_size - minified_size,
            (minified_size.to_f / original_size) * 100
          ]
        end
      end

    end

  end

end
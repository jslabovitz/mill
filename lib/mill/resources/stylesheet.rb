module Mill

  class Resource

    class Stylesheet < Resource

      FileTypes = %w{
        text/css
      }

      def load
        super
        unless @input_file.basename.to_s.end_with?('.min.css')
          engine = Sass::Engine.new(@input_file.read,
            filename: @input_file.to_s,
            syntax: :scss,
            style: :compressed)
          @content = engine.render
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

end
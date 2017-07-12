module Mill

  class Resource

    class Stylesheet < Resource

      FileTypes = %w{
        text/css
      }

      def load
        super
        unless @input_file.basename.to_s.end_with?('.min.css')
          engine = Sass::Engine.for_file(@input_file.to_s, syntax: :scss, style: :compressed)
          begin
            @content = engine.render
          rescue Sass::SyntaxError => e
            raise "#{input_file}: error parsing CSS: #{e}"
          end
        end
      end

    end

  end

end
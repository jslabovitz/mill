module Mill

  class Resource

    class Stylesheet < Resource

      FileTypes = %w{
        text/css
      }

      def load
        super
        unless @input_file.basename.to_s.end_with?('.min.css')
          engine = Sass::Engine.for_file(@input_file.to_s, style: :compressed)
          @content = engine.render
        end
      end

    end

  end

end
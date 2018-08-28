module Mill

  class Resource

    class Stylesheet < Resource

      FileTypes = %w{
        text/css
      }

      def load
        super
        unless @input_file.basename.to_s.end_with?('.min.css')
          begin
            @content = SassC::Engine.new(@input_file.read, syntax: :scss, style: :compressed).render
          rescue SassC::SyntaxError => e
            raise "#{input_file}: error parsing CSS: #{e}"
          end
        end
      end

    end

  end

end
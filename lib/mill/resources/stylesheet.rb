module Mill

  class Resource

    class Stylesheet < Resource

      FileTypes = %w{
        text/css
      }

      def load
        super
        raise Error, "Input must be file" unless @input.kind_of?(Path)
        unless @input.basename.to_s.end_with?('.min.css')
          begin
            @output = SassC::Engine.new(@input.read, syntax: :scss, style: :compressed).render
          rescue SassC::SyntaxError => e
            raise "#{@input}: error parsing CSS: #{e}"
          end
        end
      end

    end

  end

end
module Mill

  class Resource

    class Textile < Markup

      FileTypes = %w{
        text/textile
      }

      def parse_text(text)
        RedCloth.new((text || '').strip, [:no_span_caps]).to_html
      end

    end

  end

end
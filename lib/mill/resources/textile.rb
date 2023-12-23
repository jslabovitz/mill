module Mill

  class Resource

    class Textile < Markup

      FileTypes = %w{
        text/textile
      }

      MIME::Types.add(MIME::Type.new(['text/textile', %w[textile]])) if MIME::Types['text/textile'].empty?

      def parse_text(text)
        RedCloth.new((text || '').strip, [:no_span_caps]).to_html
      end

    end

  end

end
module Mill

  class Resource

    class Textile < Markup

      FileTypes = %w{
        text/textile
      }

      if MIME::Types['text/textile'].empty?
        type = MIME::Type.new(
          'content-type'        => 'text/textile',
          'preferred-extension' => 'textile',
        )
        MIME::Types.add(type)
      end

      def parse_text(text)
        RedCloth.new((text || '').strip, [:no_span_caps]).to_html
      end

    end

  end

end
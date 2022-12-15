module Mill

  class Resource

    class Markdown < Markup

      FileTypes = %w{
        text/markdown
      }

      def parse_text(text)
        Kramdown::Document.new((text || '').strip).to_html
      end

    end

  end

end
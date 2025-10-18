module Mill

  class Resource

    class Markdown < Markup

      FileTypes = %w{
        text/markdown
        text/x-web-markdown
      }

      def parse_text(text)
        Kramdown::Document.new((text || '').strip).to_html
      end

    end

  end

end
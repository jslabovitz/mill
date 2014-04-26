module Mill

  module Filters

    class MarkdownToHTML < Filter

      def process(resource)
        log.debug(2) { "converting Markdown to HTML" }
        builder = Nokogiri::HTML::Builder.new(encoding: 'utf-8') do |builder|
          builder.html do
            builder.head do
              builder.title(resource.title) if resource.title
            end
            builder.body do
              doc = Nokogiri::HTML(resource.data.to_html)
              builder << doc.to_html
            end
          end
        end
        resource.data = builder.doc
        resource.dest_file = resource.dest_file.replace_extension('.html')
      end

    end

  end

end
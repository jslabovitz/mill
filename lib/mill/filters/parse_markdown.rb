module Mill

  module Filters

    class ParseMarkdown < Filter

      def process(resource)
        log.debug(2) { "parsing Markdown" }
        if resource.data =~ /^\w+:\s+/
          header, resource.data = resource.data.split(/\n\n/, 2)
          header.split(/\n/).each do |line|
            key, value = line.strip.split(/:\s+/)
            resource.send("#{key.downcase}=", value)
          end
        end
        skip if resource.draft?
        resource.data = Kramdown::Document.new(resource.data)
      end

    end

  end

end
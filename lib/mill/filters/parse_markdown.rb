module Mill

  module Filters

    class ParseMarkdown < Filter

      def process(resource)
        log.debug(2) { "parsing Markdown" }
        if resource.data =~ /^\w+:\s+/
          header, resource.data = resource.data.split(/\n\n/, 2)
          params = HashStruct.new
          header.split(/\n/).each do |line|
            key, value = line.strip.split(/:\s+/)
            params[key.downcase.to_sym] = value
          end
          params.each { |k, v| resource.send("#{k}=", v) }
        end
        resource.data = Kramdown::Document.new(resource.data)
      end

    end

  end

end
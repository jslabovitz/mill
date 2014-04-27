module Mill

  module Filters

    class ParseMarkdown < Filter

      def process(resource)
        log.debug(2) { "parsing Markdown" }
        if resource.data =~ /^\w+:\s+/
          header, resource.data = resource.data.split(/\n\n/, 2)
          params = {}
          header.split(/\n/).each do |line|
            key, value = line.strip.split(/:\s+/)
            key = key.downcase.to_sym
            value = case key
            when :date
              DateTime.parse(value)
            when :title
              value
            when :status
              value.split(/\s/).map(&:downcase).map(&:to_sym)
            else
              raise "Unknown Markdown header: #{line.inspect}"
            end
            params[key] = value
          end
          params.each { |k, v| resource.send("#{k}=", v) }
        end
        resource.data = Kramdown::Document.new(resource.data)
      end

    end

  end

end
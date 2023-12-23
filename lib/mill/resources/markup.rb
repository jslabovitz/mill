module Mill

  class Resource

    class Markup < Resource

      def printable
        super + [
          :header,
          { label: 'Text', value: @text[0...100] + '...' },
        ]
      end

      def load
        @text = case @input
        when Path
          @input.read
        when String
          @input.dup
        else
          raise Error, "Unknown markup input: #{@input.class}"
        end
        @header = HashStruct.new
        if @text.split(/\n/, 2).first =~ /^\w+:\s+/
          fields = {}
          lines, @text = @text.split(/\n\n/, 2)
          lines.split(/\n/).each do |line|
            if line.start_with?(/\s+/)
              key = fields.keys.last
              fields[key] += line
            else
              key, value = line.strip.split(/:\s*/, 2)
              fields[key] = value
            end
          end
          @header = HashStruct.new(fields)
        end
      end

      def parse_text(text)
        # implemented in subclass
      end

      def convert_class
        @site.resource_class_for_type('text/html')
      end

      def convert
        return nil if @header[:draft]
        convert_class.new(
          path: @path.sub(%r{\.\w+$}, '.html'),
          input: parse_text(@text),
          date: @date,
          **@header,
        )
      end

    end

  end

end
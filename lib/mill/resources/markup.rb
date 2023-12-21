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
        @header = {}
        if @text.split(/\n/, 2).first =~ /^\w+:\s+/
          header_block, @text = @text.split(/\n\n/, 2)
          @header = {}
          header_block.split(/\n/).each do |line|
            if line.start_with?(/\s+/)
              key = @header.keys.last
              @header[key] += line
            else
              key, value = line.strip.split(/:\s*/, 2)
              key = key.gsub('-', '_').downcase.to_sym
              @header[key] = value
            end
          end
        end
      end

      def parse_text(text)
        # implemented in subclass
      end

      def convert_class
        @site.resource_class_for_type('text/html')
      end

      def convert
        return nil if @header[:draft] == 'true' || @header[:draft] == true
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
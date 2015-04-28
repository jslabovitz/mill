class String

  def to_html
    Nokogiri::HTML.fragment(Kramdown::Document.new(self).to_html).at_xpath('p').children.to_html
  end

end

class Mill

  class Resource

    class Markdown < HTML

      def self.file_extensions
        %w{
          .md .markdown
        }
      end

      def load
        load_date
        @output_file = @output_file.replace_extension('.html')
        @content = @input_file.read
        load_text_header
        @content = parse_html(Kramdown::Document.new(@content).to_html)
      end

      def load_text_header
        if @content =~ /^\w+:\s+/
          header, @content = @content.split(/\n\n/, 2)
          header.split(/\n/).each do |line|
            key, value = line.strip.split(/:\s+/, 2)
            key = key.gsub('-', '_').downcase.to_sym
            raise "Unknown key in text header: #{line.inspect}" unless respond_to?(key)
            send("#{key}=", value)
          end
        end
      end

    end

  end

end
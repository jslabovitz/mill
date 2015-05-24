class Mill

  class Importers

    class Text < Importer

      include HTMLHelpers

      def process
        @content = @input_file.read
        preprocess
        markup_class = case @input_file.extname
        when '.md', '.mdown', '.markdown'
          Kramdown::Document
        when '.textile'
          RedCloth
        else
          PreText
        end
        @content = parse_html(markup_class.new(@content).to_html)
        @output_file = @output_file.replace_extension('.html')
      end

      def preprocess
        if @content =~ /^\w+:\s+/
          header, @content = @content.split(/\n\n/, 2)
          header.split(/\n/).map do |line|
            key, value = line.strip.split(/:\s+/, 2)
            key = key.gsub('-', '_').downcase.to_sym
            @metadata[key] = value
          end
        end
      end

    end

  end

end
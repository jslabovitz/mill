class Mill

  class Importers

    class HTML < Importer

      include HTMLHelpers

      def process
        begin
          @content = parse_html(@input_file.read)
        rescue HTMLError => e
          raise "failed to parse #{@input_file}: #{e}"
        end
        @metadata[:date] = @input_file.mtime
        @metadata[:title] = content.at_xpath('/html/head/title').text
        @content.xpath('/html/head/meta[@name]').each do |meta|
          @metadata[meta['name'].to_sym] = meta['content']
        end
        #FIXME: warn about elements not imported from head?
        @content = @content.at_xpath('/html/body').children
      end

    end

  end

end
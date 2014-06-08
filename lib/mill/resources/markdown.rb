class Mill

  class Resource

    class Markdown < Resource

      attr_accessor :status

      def status=(status)
        @status = case status
        when Symbol
          status
        else
          status.to_s.downcase.to_sym
        end
      end

      def draft?
        @status == :draft
      end

      def invisible?
        @status == :invisible
      end

      def load
        super
        read_file
        parse_header
      end

      def process
        convert_to_html
      end

      def parse_header
        if @data =~ /^\w+:\s+/
          log.debug(3) { "parsing header" }
          header, @data = @data.split(/\n\n/, 2)
          header.split(/\n/).each do |line|
            key, value = line.strip.split(/:\s+/)
            key = key.gsub('-', '_').downcase.to_sym
            send("#{key}=", value)
          end
        end
      end

      def convert_to_html
        # return if draft?
        log.debug(3) { "converting Markdown to HTML" }
        builder = Nokogiri::HTML::Builder.new(encoding: 'utf-8') do |builder|
          builder.html do
            builder.head do
              builder.title(@title) if @title
            end
            builder.body do
              builder << Kramdown::Document.new(@data).to_html
            end
          end
        end
        @data = builder.doc
        @type = :html
      end

    end

  end

end
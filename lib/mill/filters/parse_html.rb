module Mill

  module Filters

    class ParseHTML < Filter

      def process(resource)
        unless resource.data.kind_of?(Nokogiri::HTML::Document)
          log.debug(2) { "parsing HTML" }
          resource.data = Nokogiri::HTML(resource.data) { |config| config.strict }
          resource.data.errors.reject { |e| e.message =~ /Tag members? invalid/ }.each do |error|
            log.error(2) { "#{resource.dest_file}: Error in HTML: #{error.line}:#{error.column}: #{error.message}" }
          end
        end
      end
    end

  end

end
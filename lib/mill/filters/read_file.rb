module Mill

  module Filters

    class ReadFile < Filter

      def process(resource)
        log.debug(2) { "reading file #{resource.src_file.to_s.inspect}" }
        resource.date ||= resource.src_file.mtime
        resource.title ||= resource.src_file.basename.without_extension
        resource.data ||= resource.src_file.read
      end

    end

  end

end
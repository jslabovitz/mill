module Mill

  module Filters

    class CopyFile < Filter

      def process(resource)
        log.debug(2) { "copying file #{resource.dest_file.to_s.inspect}" }
        resource.dest_file.dirname.mkpath unless resource.dest_file.dirname.exist?
        resource.src_file.cp(resource.dest_file)
      end

    end

  end

end
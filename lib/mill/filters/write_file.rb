module Mill

  module Filters

    class WriteFile < Filter

      def process(resource)
        log.debug(2) { "writing file #{resource.dest_file.to_s.inspect}" }
        resource.dest_file.dirname.mkpath unless resource.dest_file.dirname.exist?
        resource.dest_file.open('w') { |io| io.write(resource.data.to_s) }
        resource.dest_file.utime(resource.date, resource.date)
      end

    end

  end

end
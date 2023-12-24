module Mill

  module Commands

    class Types < Command

      def run(args)
        super
        @site.file_types.sort.each do |type, klass|
          puts '%-40s %s' % [type, klass]
        end
      end

    end

  end

end
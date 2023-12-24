module Mill

  module Commands

    class Types < Command

      def run(args)
        super
        @site.print_file_types
      end

    end

  end

end
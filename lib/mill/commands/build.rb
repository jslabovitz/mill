module Mill

  module Commands

    class Build < Command

      def run(args)
        super
        @site.build
        @site.save
      end

    end

  end

end
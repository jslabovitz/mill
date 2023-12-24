module Mill

  module Commands

    class Snapshot < Command

      def run(args)
        super
        @site.snapshot
      end

    end

  end

end
module Mill

  module Commands

    class Diff < Command

      def run(args)
        super
        @site.diff
      end

    end

  end

end
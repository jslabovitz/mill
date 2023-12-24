module Mill

  module Commands

    class Clean < Command

      def run(args)
        super
        @site.clean
      end

    end

  end

end
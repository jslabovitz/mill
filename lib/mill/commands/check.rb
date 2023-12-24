module Mill

  module Commands

    class Check < Command

      def run(args)
        super
        @site.check
      end

    end

  end

end
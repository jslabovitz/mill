module Mill

  module Commands

    class List < Command

      def run(args)
        super
        @site.list
      end

    end

  end

end
module Mill

  module Commands

    class Tree < Command

      def run(args)
        super
        @site.build
        @site.resources.print_tree
      end

    end

  end

end
module Mill

  module Commands

    class Upload < Command

      def run(args)
        super
        @site.upload
      end

    end

  end

end
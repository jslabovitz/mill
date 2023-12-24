module Mill

  module Commands

    class List < Command

      def run(args)
        super
        @site.build
        @site.resources.each do |resource|
          resource.print
          puts
        end
      end

    end

  end

end
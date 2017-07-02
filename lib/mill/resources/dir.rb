module Mill

  class Resource

    class Index < Text

      include HTMLHelpers

      attr_accessor :pages

      def initialize(pages:, **args)
        @pages = pages
        super(**args)
      end

      def load
        super
        @content = html_fragment do |html|
          html.dl do
            @pages.each do |page|
              html.dt(page.title)
            end
          end
        end
      end

    end

  end

end
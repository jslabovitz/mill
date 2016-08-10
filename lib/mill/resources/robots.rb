# see http://www.robotstxt.org/robotstxt.html

module Mill

  class Resource

    class Robots < Resource

      def self.type
        :robots
      end

      def load
        info = {
          'Sitemap' => @mill.sitemap_resource.absolute_uri,
        }
        @content = info.map { |key, value| "#{key}: #{value}" }.join("\n")
        super
      end

    end

  end

end
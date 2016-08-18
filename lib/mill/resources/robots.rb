# see http://www.robotstxt.org/robotstxt.html

module Mill

  class Resource

    class Robots < Resource

      def build
        info = {
          'Sitemap' => @site.sitemap_resource.absolute_uri,
        }
        @content = info.map { |key, value| "#{key}: #{value}" }.join("\n")
        super
      end

    end

  end

end
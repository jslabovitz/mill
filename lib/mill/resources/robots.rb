# see http://www.robotstxt.org/robotstxt.html

class Mill

  class Resource

    class Robots < Resource

      def process
        info = {
          'Sitemap' => @mill.site_uri + @mill.sitemap_uri,
        }
        @content = info.map { |key, value| "#{key}: #{value}" }.join("\n")
      end

    end

  end

end
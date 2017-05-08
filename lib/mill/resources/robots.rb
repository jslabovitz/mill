# see http://www.robotstxt.org/robotstxt.html

module Mill

  class Resource

    class Robots < Resource

      def build
        info = {}
        info['User-Agent'] = '*'
        info['Disallow'] = '/' unless @site.allow_robots
        info['Sitemap'] = @site.sitemap_resource.absolute_uri if @site.make_sitemap
        @content = info.map { |key, value| "#{key}: #{value}" }.join("\n")
        super
      end

    end

  end

end
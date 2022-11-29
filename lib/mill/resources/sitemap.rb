# see http://www.sitemaps.org/protocol.php

module Mill

  class Resource

    class Sitemap < Resource

      def build
        @output = Nokogiri::XML::Builder.new do |xml|
          xml.urlset('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9',
                     'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                     'xsi:schemaLocation' => 'http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd') do
            @site.sitemap_resources.each do |resource|
              xml.url do
                xml.loc(resource.absolute_uri)
                xml.lastmod(resource.date.iso8601)
                xml.changefreq(resource.change_frequency.to_s)
              end
            end
          end
        end.doc
      end

    end

  end

end
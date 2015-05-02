# see http://www.sitemaps.org/protocol.php

class Mill

  class Resource

    class Feed < Resource

      def process
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.feed(xmlns: 'http://www.w3.org/2005/Atom') do
            xml.id(@mill.site_uri)
            xml.generator(@mill.site_uri)
            xml.title(@mill.site_title)
            xml.link(rel: 'alternate', type: 'text/html',             href: @mill.site_uri)
            xml.link(rel: 'self',      type: 'application/atom+xml',  href: uri)
            xml.author do
              xml.name(@author_name) if @author_name
              xml.uri(@author_link) if @author_url
              xml.email("mailto:#{@author_email}") if @author_email
            end
            resources = @mill.public_resources.sort_by(&:date)
            xml.updated(resources.last.date)
            resources.each do |resource|
              content_html = resource.content.xpath('//p[1]').children
              xml.entry do
                xml.title(resource.title) if resource.title
                xml.id(@mill.site_uri + resource.uri)
                # xml.summary do
                # end
                xml.updated(resource.date)
                xml.published(resource.date)
                xml.content(type: 'html') do
                  xml.cdata(content_html.to_html)
                end
              end
            end
          end
        end
        @content = builder.doc
      end

      def link_html
        html = Nokogiri::HTML.fragment('')
        builder = Nokogiri::HTML::Builder.with(html) do |builder|
          builder.link(href: uri, rel: 'alternate', type: 'application/atom+xml')
        end
        html
      end

    end

  end

end
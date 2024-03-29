module Mill

  class Resource

    class Feed < Resource

      def build
        resources = @site.feed_resources
        @output = Nokogiri::XML::Builder.new do |xml|
          xml.feed(xmlns: 'http://www.w3.org/2005/Atom') do
            xml.id(@site.tag_uri)
            xml.title(@site.site_title) if @site.site_title
            xml.link(rel: 'alternate', type: 'text/html',             href: @site.root_resource.absolute_uri) if @site.root_resource
            xml.link(rel: 'self',      type: 'application/atom+xml',  href: absolute_uri)
            xml.author do
              xml.name(@site.feed_author_name) if @site.feed_author_name
              xml.uri(@site.feed_author_uri) if @site.feed_author_uri
              xml.email(@site.feed_author_email) if @site.feed_author_email
            end
            xml.updated(resources.last.date.iso8601) unless resources.empty?
            resources.each do |resource|
              xml.entry do
                xml.title(resource.title) if resource.title
                xml.link(rel: 'alternate', href: resource.absolute_uri)
                xml.id(resource.tag_uri)
                xml.updated(resource.date.iso8601)
                xml.published(resource.date.iso8601)
                if (html = resource.feed_content)
                  xml.content(type: 'html') { xml.cdata(html.to_html) }
                end
              end
            end
          end
        end.doc
      end

      def build_link(html)
        html.link(href: uri, rel: 'alternate', type: 'application/atom+xml')
      end

    end

  end

end
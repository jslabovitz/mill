# see http://www.sitemaps.org/protocol.php

class Mill

  class Resource

    class Feed < Resource

      include HTMLHelpers

      def process
        resources = @mill.public_resources.sort_by(&:date)
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.feed(xmlns: 'http://www.w3.org/2005/Atom') do
            xml.id(@mill.tag_uri)
            xml.generator(*@mill.feed_generator)
            xml.title(@mill.site_title)
            xml.link(rel: 'alternate', type: 'text/html',             href: @mill.home_resource.uri)
            xml.link(rel: 'self',      type: 'application/atom+xml',  href: absolute_uri)
            xml.author do
              xml.name(@mill.feed_author_name)
              xml.uri(@mill.feed_author_uri)
              xml.email(@mill.feed_author_email)
            end
            xml.updated(resources.last.date.iso8601)
            resources.each do |resource|
              xml.entry do
                xml.title(resource.title) if resource.title
                xml.link(rel: 'alternate', href: resource.absolute_uri)
                xml.id(resource.tag_uri)
                xml.updated(resource.date.iso8601)
                if (resource.respond_to?(:summary) && (summary = resource.summary))
                  xml.summary(type: 'html') do
                    xml.cdata(summary.to_html)
                  end
                end
                xml.content(type: 'html') do
                  xml.cdata(resource.content.to_html)
                end
              end
            end
          end
        end
        @content = builder.doc
      end

      def link_html
        html_fragment do |html|
          html.link(href: uri, rel: 'alternate', type: 'application/atom+xml')
        end
      end

    end

  end

end
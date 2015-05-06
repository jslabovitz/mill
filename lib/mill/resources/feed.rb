# see http://www.sitemaps.org/protocol.php

class Mill

  class Resource

    class Feed < Resource

      def process
        resources = @mill.public_resources.sort_by(&:date)
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.feed(xmlns: 'http://www.w3.org/2005/Atom') do
            xml.id(@mill.tag_uri)
            xml.generator(*@mill.feed_generator)
            xml.title(@mill.site_title)
            xml.link(rel: 'alternate', type: 'text/html',             href: @mill.feed_home_uri)
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
                if (resource.respond_to?(:feed_summary) && (summary = resource.feed_summary))
                  xml.summary(type: resource.feed_summary_type) do
                    xml.cdata(summary)
                  end
                end
                if (resource.respond_to?(:feed_content) && (content = resource.feed_content))
                  xml.content(type: resource.feed_content_type) do
                    xml.cdata(content)
                  end
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
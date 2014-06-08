class Mill

  class Feed < Resource

    attr_accessor :site_title
    attr_accessor :site_link
    attr_accessor :feed_link
    attr_accessor :author_name
    attr_accessor :author_link
    attr_accessor :author_email

    def initialize(params={})
      params.each { |k, v| send("#{k}=", v) }
    end

    def site_link=(uri)
      @site_link = Addressable::URI.parse(uri)
    end

    def author_link=(uri)
      @author_link = Addressable::URI.parse(uri)
    end

    def feed_xml
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.feed(:xmlns => 'http://www.w3.org/2005/Atom') do
        xml.id(@site_link)
        xml.generator(@site_link)
        xml.title(@site_title)
        xml.link(rel: 'alternate', type: 'text/html',             href: @site_link)
        xml.link(rel: 'self',      type: 'application/atom+xml',  href: @feed_link)
        xml.author do
          xml.name(@author_name) if @author_name
          xml.uri(@author_link) if @author_link
          xml.email("mailto:#{@author_email}") if @author_email
        end
        xml.updated(pages.first.mtime)
        pages.each do |page|
          xml.entry do
            xml.title(page.title)
            xml.id(@site_link.merge(page.link).to_s)
            xml.summary(page.excerpt)
            xml.updated(page.mtime)
            xml.published(page.date)
            xml.content(page.content_html, type: 'html')
          end
        end
      end
      xml
    end

  end

end
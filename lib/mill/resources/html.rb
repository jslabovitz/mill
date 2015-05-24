class Mill

  class Resource

    class HTML < Resource

      include HTMLHelpers

      attr_accessor :title

      def self.default_params
        {
          public: true,
        }
      end

      def final_content
        html_document do |doc|
          doc.html(lang: 'en') do |html|
            html.head do
              html << head.to_html
            end
            html.body do
              html << body.to_html
            end
          end
        end
      end

      def head
        ''
      end

      def body
        ''
      end

      def verify
        tidy_html(@output_file.read) do |error_str|
          warn "#{uri}: #{error_str}"
        end
      end

      def add_external_link_targets
        @content.xpath('//a').each do |a|
          if a['href'] && a['href'] =~ /^\w+:/
            a['target'] = '_blank'
          end
        end
      end

      def add_image_sizes
        @content.xpath('//img').each do |img|
          # skip elements that already have width/height defined
          next if img[:width] || img[:height]
          img_link = Addressable::URI.parse(img['src'])
          raise "no link in <img> element: #{img.to_s}" if img_link.nil? || img_link.empty?
          next if img_link.host
          img_uri = uri + img_link
          img_resource = @mill.find_resource(img_uri) or raise "Can't find image for #{img_uri}"
          img[:width], img[:height] = img_resource.width, img_resource.height
        end
      end

      def summary
        @content.at_xpath('/p[1]')
      end

    end

  end

end
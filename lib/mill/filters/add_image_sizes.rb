module Mill

  module Filters

    class AddImageSizes < Filter

      def process(resource)
        log.debug(2) { "adding image sizes" }
        resource.data.xpath('//img').each do |img|
          unless img['src'] =~ /^\w+:/
            img_link = img['src']
            img_path = resource.site.content_dir / img_link
            raise "#{resource.dest_file}: Image file #{img_path} not found for link: #{img_link}" unless img_path.exist?
            size = ImageSize.path(img_path).size
            log.debug(3) { "#{img_link}: #{size.join('x')}" }
            img[:width], img[:height] = size
          end
        end
      end

    end

  end

end
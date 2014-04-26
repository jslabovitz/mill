module Mill

  module Filters

    class AddExternalLinkTargets < Filter

      def process(resource)
        log.debug(2) { "adding link targets" }
        resource.data.xpath('//a').each do |a|
          if a['href'] && a['href'] =~ /^\w+:/
            log.debug(3) { "#{a['href']}" }
            a['target'] = '_blank'
          end
        end
      end

    end

  end

end
module Mill

  module Filters

    class DecorateHTML < Filter

      def process(resource)
        log.debug(2) { "decorating HTML" }
        resource.site.decorate_html(resource) if resource.site.respond_to?(:decorate_html)
      end

    end

  end

end
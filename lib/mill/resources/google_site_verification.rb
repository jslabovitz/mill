module Mill

  class Resource

    class GoogleSiteVerification < Resource

      attr_accessor :key

      def initialize(key:, **args)
        @key = key
        @public = false
        super(**args)
      end

      def inspect
        super + ", key: %p" % [
          @key,
        ]
      end

      def load
        @content = "google-site-verification: #{@key}.html\n"
        super
      end

    end

  end

end
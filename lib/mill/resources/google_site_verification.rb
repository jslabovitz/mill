module Mill

  class Resource

    class GoogleSiteVerification < Resource

      attr_accessor :key

      def initialize(key:, **args)
        @key = key
        @public = false
        super(**args)
      end

      def load
        @content = "google-site-verification: #{@key}\n"
        super
      end

    end

  end

end
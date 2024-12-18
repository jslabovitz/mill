module Mill

  class Resource

    class Redirect < Resource

      attr_reader   :redirect_uri
      attr_accessor :redirect_code

      def initialize(redirect_uri:, redirect_code: nil, **params)
        super(
          {
            redirect_uri: redirect_uri,
            redirect_code: redirect_code || 303,
          }.merge(params)
        )
      end

      def redirect_uri=(uri)
        @redirect_uri = Addressable::URI.parse(uri)
      end

      def printable
        super + [
          :redirect_uri,
          :redirect_code,
        ]
      end

      def build
        @output = "%s %d" % [@redirect_uri, @redirect_code]
      end

    end

  end

end
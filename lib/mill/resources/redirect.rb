module Mill

  class Resource

    class Redirect < Resource

      attr_accessor :redirect_uri
      attr_accessor :redirect_code

      def initialize(redirect_uri:, redirect_code: 303, **args)
        @redirect_uri = redirect_uri
        @redirect_code = redirect_code
        super(**args)
      end

      def load
        @content = "%s %d" % [@redirect_uri, @redirect_code]
        super
      end

      def save
        @output_file = @output_file.add_extension('.redirect')
        super
      end

    end

  end

end
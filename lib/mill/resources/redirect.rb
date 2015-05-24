class Mill

  class Resource

    class Redirect < Resource

      attr_accessor :redirect_uri
      attr_accessor :redirect_code

      def self.default_params
        {
          redirect_code: 303,
        }
      end

      def load
        @content = {
          uri: @redirect_uri,
          code: @redirect_code,
        }.to_yaml
        super
      end

      def build
        #FIXME: this is a hack
        @output_file = @output_file.add_extension('.redirect')
        super
      end

    end

  end

end
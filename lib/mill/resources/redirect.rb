class Mill

  class Resource

    class Redirect < Resource

      attr_accessor :redirect_uri
      attr_accessor :redirect_code

      def self.type
        :redirect
      end

      def initialize(params={})
        super(
          {
            redirect_code: 303,
          }.merge(params)
        )
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
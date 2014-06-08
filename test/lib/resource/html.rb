class TestMill < Mill

  class Resource

    class HTML < Mill::Resource::HTML

      def process
        decorate_html
        super
      end

      def decorate_html
        add_stylesheet(href: '/stylesheet.css')
        set_title("Test: #{title}")
        wrap_body do |builder, body|
          builder.div(id: 'sidebar') do
            builder.h1(title)
          end
          builder.div(id: 'main') do
            builder << body
          end
        end
      end

    end

  end

end
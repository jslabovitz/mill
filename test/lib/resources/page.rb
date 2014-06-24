class TestMill < Mill

  class Resource

    class Page < Mill::Resource::Page

      def decorate
        super
        add_stylesheet(href: '/stylesheet.css')
        set_title("Test: #{title}")
        wrap_body do |builder, body|
          builder.div(id: 'sidebar') do
            builder.h1(title)
          end
          builder.div(id: 'main') do
            builder << body.to_html
          end
        end
      end

    end

  end

end
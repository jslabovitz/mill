class TestMill < Mill

  class Resource

    class Markdown < Mill::Resource::Markdown

      def process
        @data += make_page_list
        super
      end

      def make_page_list
        s = []
        s << ''
        s << ''
        s << '# Other pages'
        s << ''
        (@processor.resources - [self]).each do |resource|
          s << "- [#{resource.title}](#{resource.uri})"
        end
        s.join("\n")
      end

    end

  end

end
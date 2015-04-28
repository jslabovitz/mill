class Mill

  class Navigator

    attr_accessor :uris

    def initialize(params={})
      @uris = []
      params.each { |k, v| send("#{k}=", v) }
    end

    def uris=(uris)
      @uris = uris.map { |u| Addressable::URI.parse(u) }
    end

    def nav_resources(resource)
      @uris.map do |uri|
        resource.mill[uri] or raise "Can't find navigation resource for #{uri}"
      end
    end

    def nav_for_resource(resource, &block)
      nav = {}
      within_resources = []
      nav_resources(resource).each do |nav_resource|
        nav[nav_resource] = :other
        if nav_resource.uri == resource.uri
          nav[nav_resource] = :current
        elsif Path.new(resource.uri.path).inside?(Path.new(nav_resource.uri.path).dirname)
          within_resources << nav_resource
        end
      end
      if !within_resources.empty?
        within_resource = within_resources.sort_by { |r| r.uri.path.count('/') }.last
        nav[within_resource] = :within
      end
      nav
    end

    def first_resource(resource)
      nav_resources(resource).first
    end

    def previous_resource(resource)
      resources = nav_resources(resource)
      if (index = resources.index(resource)) && index > 0
        resources[index - 1]
      end
    end

    def next_resource(resource)
      resources = nav_resources(resource)
      if (index = resources.index(resource))
        resources[index + 1]
      end
    end

    def build_current_resource(resource, builder)
      builder.em { builder << resource.title.to_html }
    end

    def build_within_resource(resource, builder)
      builder.a(href: resource.uri) { builder.em { builder << resource.title.to_html } }
    end

    def build_other_resource(resource, builder)
      builder.a(href: resource.uri) { builder << resource.title.to_html }
    end

    def build_resource(resource, builder, &block)
      builder.li do
        yield(resource, builder)
      end
    end

    def build_block(builder, &block)
      builder.ul(class: 'navigation') do
        yield(builder)
      end
    end

    def to_html(resource)
      html = Nokogiri::HTML.fragment('')
      builder = Nokogiri::HTML::Builder.with(html) do |builder|
        build_block(builder) do |builder|
          nav_for_resource(resource).each do |nav_resource, state|
            build_resource(nav_resource, builder) do |nav_resource, builder|
              case state
              when :current
                build_current_resource(nav_resource, builder)
              when :within
                build_within_resource(nav_resource, builder)
              when :other
                build_other_resource(nav_resource, builder)
              end
            end
          end
        end
      end
      html
    end

  end

end
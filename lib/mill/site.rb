module Mill

  class Site

    attr_accessor :input_dir
    attr_accessor :output_dir
    attr_accessor :site_title
    attr_accessor :site_uri
    attr_accessor :site_email
    attr_accessor :site_control_date
    attr_accessor :html_version
    attr_accessor :feed_resource
    attr_accessor :sitemap_resource
    attr_accessor :robots_resource
    attr_accessor :shorten_uris
    attr_accessor :make_feed
    attr_accessor :make_sitemap
    attr_accessor :make_robots
    attr_accessor :allow_robots
    attr_accessor :htpasswd_file
    attr_accessor :navigator
    attr_accessor :resource_classes
    attr_accessor :redirects
    attr_accessor :resources

    DefaultResourceClasses = ObjectSpace.each_object(Class).select { |c| c < Resource }

    def initialize(input_dir: 'content',
                   output_dir: 'public_html',
                   site_title: nil,
                   site_uri: 'http://localhost',
                   site_email: nil,
                   site_control_date: Date.today.to_s,
                   html_version: :html4_transitional,
                   shorten_uris: true,
                   make_feed: true,
                   make_sitemap: true,
                   make_robots: true,
                   allow_robots: true,
                   htpasswd_file: nil,
                   navigator: nil,
                   google_site_verification: nil,
                   resource_classes: [],
                   redirects: {})

      @input_dir = Path.new(input_dir)
      @output_dir = Path.new(output_dir)
      @site_title = site_title
      @site_uri = Addressable::URI.parse(site_uri)
      @site_email = Addressable::URI.parse(site_email) if site_email
      @site_control_date = Date.parse(site_control_date)
      @html_version = html_version
      @shorten_uris = shorten_uris
      @make_feed = make_feed
      @make_sitemap = make_sitemap
      @make_robots = make_robots
      @allow_robots = allow_robots
      @htpasswd_file = htpasswd_file ? Path.new(htpasswd_file) : nil
      @resource_classes = resource_classes
      @navigator = navigator
      @google_site_verification = google_site_verification
      @redirects = redirects

      @resources = []
      @resources_by_uri = {}
      build_file_types
    end

    def build_file_types
      @file_types = {}
      (DefaultResourceClasses + @resource_classes).each do |resource_class|
        resource_class.const_get(:FileTypes).each do |type|
          @file_types[type] = resource_class
        end
      end
    end

    def add_resource(resource)
      resource.site = self
      @resources << resource
      @resources_by_uri[resource.uri] = resource
      # ;;warn "added #{resource} as #{resource.uri}"
    end

    def delete_resource(resource)
      @resources.delete(resource)
      @resources_by_uri.delete(resource.uri)
    end

    def find_resource(uri)
      uri = Addressable::URI.parse(uri.to_s) unless uri.kind_of?(Addressable::URI)
      resource = @resources_by_uri[uri]
      if resource.nil? && @shorten_uris
        uri.path = uri.path.sub(%r{\.html$}, '')
        resource = @resources_by_uri[uri]
      end
      resource
    end

    def resource_for_file(path)
      find_resource(
        URI.parse(
          '/' + URI.encode(
            path.relative_to(@output_dir).to_s
          )
        )
      )
    end

    def home_resource
      find_resource('/')
    end

    def tag_uri
      'tag:%s:' % [
        [
          @site_uri.host.downcase,
          @site_control_date
        ].join(','),
      ]
    end

    def feed_generator
      [
        'Mill',
        {
          uri: Addressable::URI.parse('http://github.com/jslabovitz/mill'),
          version: Mill::VERSION,
        }
      ]
    end

    def feed_author_name
      @site_title
    end

    def feed_author_uri
      @site_uri
    end

    def feed_author_email
      @site_email
    end

    def feed_resources
      public_resources.sort_by(&:date)
    end

    def public_resources
      @resources.select(&:public)
    end

    def private_resources
      @resources.select { |r| r.kind_of?(Resource::Text) && !r.public }
    end

    def redirect_resources
      @resources.select { |r| r.kind_of?(Resource::Redirect) }
    end

    def make
      build
      save
    end

    def list
      build
      on_each_resource do |resource|
        puts resource.inspect
      end
    end

    def build
      import_resources
      load_resources
      build_resources
    end

    def import_resources
      add_files
      add_redirects
      add_google_site_verification if @google_site_verification
      add_feed if @make_feed
      add_sitemap if @make_sitemap
      add_robots if @make_robots
      add_htpasswd if @htpasswd_file
    end

    def load_resources
      on_each_resource do |resource|
        # ;;warn "#{resource.uri}: loading"
        resource.load
      end
    end

    def build_resources
      on_each_resource do |resource|
        # ;;warn "#{resource.uri}: building"
        resource.build
      end
    end

    def save
      @output_dir.rmtree if @output_dir.exist?
      @output_dir.mkpath
      on_each_resource do |resource|
        # ;;warn "#{resource.uri}: saving"
        resource.save
      end
    end

    def on_each_resource(&block)
      @resources.each do |resource|
        old_uri = resource.uri.dup
        begin
          yield(resource)
        rescue Error => e
          raise e, "#{resource.input_file || '-'} (#{old_uri}): #{e}"
        end
        if resource.uri != old_uri
          # ;;warn "URI changed: #{old_uri} => #{resource.uri}"
          @resources_by_uri.delete(old_uri)
          @resources_by_uri[resource.uri] = resource
        end
      end
    end

    private

    def resource_class_for_file(file)
      MIME::Types.of(file.to_s).each do |type|
        if (klass = @file_types[type.content_type])
          return [klass, type]
        end
      end
      nil
    end

    def add_files
      raise Error, "Input path not found: #{@input_dir}" unless @input_dir.exist?
      @input_dir.find do |input_file|
        if input_file.basename.to_s[0] == '.'
          Find.prune
        elsif input_file.directory?
          # skip
        elsif (klass, type = resource_class_for_file(input_file))
          resource = klass.new(
            input_file: input_file,
            output_file: @output_dir / input_file.relative_to(@input_dir),
            type: type)
          add_resource(resource)
        else
          warn "Warning: can't determine resource of file: #{input_file} (#{MIME::Types.of(input_file.to_s).join(', ').inspect})"
        end
      end
    end

    def add_feed
      @feed_resource = Resource::Feed.new(
        output_file: @output_dir / 'feed.xml')
      add_resource(@feed_resource)
    end

    def add_sitemap
      @sitemap_resource = Resource::Sitemap.new(
        output_file: @output_dir / 'sitemap.xml')
      add_resource(@sitemap_resource)
    end

    def add_robots
      @robots_resource = Resource::Robots.new(
        output_file: @output_dir / 'robots.txt')
      add_resource(@robots_resource)
    end

    def add_redirects
      if @redirects
        @redirects.each do |from, to|
          output_file = @output_dir / Path.new(from).relative_to('/')
          resource = Resource::Redirect.new(
            output_file: output_file,
            redirect_uri: to)
          add_resource(resource)
        end
      end
    end

    def add_google_site_verification
      resource = Resource::GoogleSiteVerification.new(
        output_file: (@output_dir / @google_site_verification).add_extension('.html'),
        key: @google_site_verification)
      add_resource(resource)
    end

    def add_htpasswd
      resource = Resource::Other.new(
        input_file: @htpasswd_file,
        output_file: @output_dir / '.htpasswd')
      add_resource(resource)
    end

  end

end
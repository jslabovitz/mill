module Mill

  class Site

    attr_accessor :config
    attr_reader   :feed_resource
    attr_reader   :sitemap_resource
    attr_reader   :robots_resource
    attr_reader   :redirects
    attr_reader   :resources
    attr_reader   :file_types

    def self.load(dir=nil)
      config = BaseConfig.make(dir: dir)
      config = config.load_yaml(config.dir / ConfigFileName)
      site_file = config.dir / config.code_dir / 'site.rb'
      klass = load_site_class(site_file)
      klass.new(config)
    end

    def self.load_site_class(site_file)
      Kernel.load(site_file.expand_path.to_s) if site_file.exist?
      site_classes = subclasses
      if site_classes.length == 0
        self
      elsif site_classes.length > 1
        raise Error, "More than one #{self.class} class defined"
      else
        site_classes.first
      end
    end

    def initialize(config)
      @config = config
      @redirects = {}
      @resources = Resources.new
      make_file_types
    end

    def inspect
      "<#{self.class}>"
    end

    def input_dir = @config.dir / @config.input_dir
    def output_dir = @config.dir / @config.output_dir
    def site_uri = @config.site_uri
    def site_rsync = @config.site_rsync
    def site_title = @config.site_title
    def site_email = @config.site_email
    def site_postal = @config.site_postal
    def site_phone = @config.site_phone
    def site_instagram = @config.site_instagram
    def site_control_date = @config.site_control_date
    def html_version = @config.html_version
    def make_error? = @config.make_error
    def make_feed? = @config.make_feed
    def make_sitemap? = @config.make_sitemap
    def make_robots? = @config.make_robots
    def allow_robots? = @config.allow_robots

    def make_file_types
      @file_types = {}
      get_file_types(Resource)
    end

    def get_file_types(klass)
      klass.subclasses.each do |resource_class|
        resource_class.const_get(:FileTypes).each do |type|
          @file_types[type] = resource_class
        end
        get_file_types(resource_class)
      end
    end

    def add_resource(resource)
      # ;;warn "adding #{resource.class} as #{resource.path}"
      resource.site = self
      resource.load
      @resources << resource
    end

    def find_resource(path)
      @resources[path]
    end

    def root_resource
      @resources['/']
    end

    def tag_uri
      'tag:%s:' % [
        [
          site_uri.host.downcase,
          site_control_date
        ].join(','),
      ]
    end

    def feed_author_name
      site_title
    end

    def feed_author_uri
      site_uri
    end

    def feed_author_email
      site_email
    end

    def feed_resources
      primary_resources
    end

    def sitemap_resources
      primary_resources
    end

    def primary_resources
      @resources.select(&:primary?).sort_by(&:date)
    end

    def build
      load_resources
      convert_resources
      build_resources
      check
    end

    def load_resources
      add_files
      add_redirects
      add_error if make_error?
      add_feed if make_feed?
      add_sitemap if make_sitemap?
      add_robots if make_robots?
    end

    def build_resources
      @resources.each do |resource|
        # ;;warn "#{resource.path}: building"
        resource.build
      end
    end

    def convert_resources
      @resources.select { |r| r.respond_to?(:convert) }.each do |resource|
        new_resource = resource.convert
        @resources.delete(resource)
        if new_resource
          new_resource.load
          add_resource(new_resource)
        end
      end
    end

    def save
      if output_dir.exist?
        output_dir.children.reject { |p| p.basename.to_s == '.git' }.each do |path|
          path.rm_rf
        end
      else
        output_dir.mkpath
      end
      @resources.each do |resource|
        # ;;warn "#{resource.path}: saving"
        resource.save
      end
    end

    def check(external: false)
      build if @resources.empty?
      @resources.of_class(Resource::Page).each do |resource|
        resource.links.each do |link|
          begin
            check_uri(link, external: external)
          rescue Error => e
            warn "#{resource.path}: #{e}"
          end
        end
      end
    end

    def resource_class_for_file(file)
      types = MIME::Types.type_for(file.to_s)
      content_type = types.last&.content_type or raise Error, "Can't determine content type: #{file.to_s.inspect}"
      resource_class_for_type(content_type) or raise Error, "Unknown file type: #{file.to_s.inspect} (#{types.join(', ')})"
    end

    def resource_class_for_type(type)
      @file_types[type]
    end

    private

    def add_files
      raise Error, "Input directory not found: #{input_dir}" unless input_dir.exist?
      input_dir.find do |input_file|
        if input_file.basename.to_s[0] == '.'
          Find.prune
        elsif input_file.basename.to_s == "Icon\r"
          # skip macOS garbage file
        elsif input_file.directory?
          # skip directories
        else (klass = resource_class_for_file(input_file))
          resource = klass.new(input: input_file, path: '/' + input_file.relative_to(input_dir).to_s)
          add_resource(resource)
        end
      end
    end

    def add_error
      input = Simple::Builder.parse_html_document(
        Kramdown::Document.new(
          %Q{
            Something went wrong.
            The page you were looking for doesn’t exist or couldn’t be displayed.
            Please try another option.
          }.gsub(/\s+/, ' ').strip
        ).to_html
      )
      klass = resource_class_for_type('text/html')
      @error_resource = klass.new(
        path: '/error.html',
        title: 'Error',
        primary: false,
        input: input)
      add_resource(@error_resource)
    end

    def add_feed
      @feed_resource = Resource::Feed.new(path: '/feed.xml')
      add_resource(@feed_resource)
    end

    def add_sitemap
      @sitemap_resource = Resource::Sitemap.new(path: '/sitemap.xml')
      add_resource(@sitemap_resource)
    end

    def add_robots
      @robots_resource = Resource::Robots.new(path: '/robots.txt')
      add_resource(@robots_resource)
    end

    def add_redirects
      if @redirects
        @redirects.each do |from, to|
          resource = Resource::Redirect.new(path: Path.new(from).add_extension('.redirect').to_s, redirect_uri: to)
          add_resource(resource)
        end
      end
    end

    def check_uri(uri, external: false)
      if uri.relative?
        unless find_resource(uri.path)
          raise Error, "NOT FOUND: #{uri}"
        end
      elsif external
        if uri.scheme.start_with?('http')
          # warn "checking external URI: #{uri}"
          begin
            check_external_uri(uri)
          rescue => e
            raise Error, "external URI: #{uri}: #{e}"
          end
        else
          warn "Don't know how to check URI: #{uri}"
        end
      end
    end

    def check_external_uri(uri)
      response = HTTP.timeout(3).get(uri)
      case response.code
      when 200...300
        # ignore
      when 300...400
        redirect_uri = Addressable::URI.parse(response.headers['Location'])
        check_external_uri(uri + redirect_uri)
      when 404
        raise Error, "URI not found: #{uri}"
      when 999
        # ignore bogus LinkedIn status
      else
        raise Error, "Bad status from #{uri}: #{response.inspect}"
      end
    end

  end

end
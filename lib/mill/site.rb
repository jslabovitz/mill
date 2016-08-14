module Mill

  class Site

    attr_accessor :input_dir
    attr_accessor :output_dir
    attr_accessor :site_title
    attr_accessor :site_uri
    attr_accessor :site_email
    attr_accessor :site_control_date
    attr_accessor :feed_resource
    attr_accessor :sitemap_resource
    attr_accessor :robots_resource
    attr_accessor :final_destination
    attr_accessor :beta_destination
    attr_accessor :resources
    attr_accessor :shorten_uris
    attr_accessor :navigator
    attr_accessor :navigator_items
    attr_accessor :resource_classes
    attr_accessor :schema_types
    attr_accessor :redirects
    attr_accessor :input_file_type_order

    DefaultResourceClasses = [
      Resource::Text,
      Resource::Image,
      Resource::Generic,
    ]

    SchemasDir = Path.new(__FILE__).dirname / 'schemas'

    DefaultSchemaTypes = {
      feed: SchemasDir / 'atom.xsd',
      sitemap: SchemasDir / 'sitemap.xsd',
    }

    def initialize(params={})
      @resource_classes = {}
      @resources = []
      @resources_by_uri = {}
      @schema_types = {}
      @schemas = {}
      @shorten_uris = true
      @input_file_type_order = [:generic, :image, :text]
      params.each { |k, v| send("#{k}=", v) }
      build_file_types
      build_resource_classes
      load_schemas
      make_navigator
    end

    def input_dir=(path)
      @input_dir = Path.new(path).expand_path
    end

    def output_dir=(path)
      @output_dir = Path.new(path).expand_path
    end

    def site_uri=(uri)
      @site_uri = Addressable::URI.parse(uri)
    end

    def site_control_date=(date)
      begin
        @site_control_date = Date.parse(date)
      rescue ArgumentError => e
        raise "bad control date #{date.inspect}: #{e}"
      end
    end

    def file_type(file)
      if file.directory? || file.basename.to_s[0] == '.'
        return :ignore
      else
        MIME::Types.of(file.to_s).each do |mime_type|
          if (type = @file_types[mime_type.content_type])
            return type
          end
        end
      end
      nil
    end

    def add_resource(resource)
      resource.mill = self
      @resources << resource
      @resources_by_uri[resource.uri] = resource
      # ;;warn "added #{resource} as #{resource.uri}"
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

    def home_resource
      find_resource('/') or raise "Can't find home"
    end

    def schema_for_type(type)
      @schemas[type]
    end

    def tag_uri
      "tag:#{@site_uri.host.downcase},#{@site_control_date}:"
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

    def public_resources
      @resources.select(&:public)
    end

    def private_resources
      @resources.select { |r| r.kind_of?(Resource::Text) && !r.public }
    end

    def clean
      @output_dir.rmtree if @output_dir.exist?
      @output_dir.mkpath
    end

    def import
      warn "importing resources..."
      add_files
      add_redirects
      add_feed
      add_sitemap
      add_robots
    end

    def load
      warn "loading #{@resources.length} resources..."
      @resources.each do |resource|
        # ;;warn "loading resource: #{resource.uri}"
        old_uri = resource.uri.dup
        begin
          resource.load
        rescue => e
          warn "Failed to load resource #{resource.uri}: #{e}"
          raise
        end
        if resource.uri != old_uri
          # ;;warn "updating resource URI: #{old_uri} => #{resource.uri}"
          @resources_by_uri.delete(old_uri)
          @resources_by_uri[resource.uri] = resource
        end
      end
    end

    def build
      warn "building #{@resources.length} resources..."
      make_navigator
      @resources.each do |resource|
        # ;;warn "building resource: #{resource.uri}"
        begin
          resource.build
        rescue => e
          warn "Failed to build resource #{resource.uri}: #{e}"
          raise
        end
      end
    end

    def save
      warn "saving #{@resources.length} resources..."
      @resources.each do |resource|
        # ;;warn "saving resource: #{resource.uri}"
        begin
          resource.save
        rescue => e
          warn "Failed to save resource #{resource.uri}: #{e}"
          raise
        end
      end
    end

    def check
      warn "checking site..."
      checker = Checker.new(@output_dir)
      uris = [
        home_resource,
        *private_resources,
        feed_resource,
        sitemap_resource,
        robots_resource,
      ].map(&:uri)
      uris += @redirects.keys if @redirects
      uris.each do |uri|
        uri = Addressable::URI.parse('http://' + uri)
        checker.check(uri)
      end
      checker.report
    end

    def publish_beta
      raise "No beta destination configured" unless @beta_destination
      publish(@beta_destination)
    end

    def publish_final
      raise "No final destination configured" unless @final_destination
      publish(@final_destination)
    end

    def server
      server = Server.new(
        root: @output_dir,
        multihosting: false)
      server.run
    end

    private

    def add_files
      input_files_by_type.each do |type, input_files|
        input_files.each do |input_file|
          resource_class = @resource_classes[type] or raise "No resource class for #{input_file}"
          resource = resource_class.new(
            input_file: input_file,
            output_file: @output_dir / input_file.relative_to(@input_dir))
          add_resource(resource)
        end
      end
    end

    def input_files_by_type
      hash = {}
      raise "Input path not found: #{@input_dir}" unless @input_dir.exist?
      @input_dir.find do |input_file|
        input_file = @input_dir / input_file
        type = file_type(input_file) or raise "Can't determine file type of #{input_file}"
        unless type == :ignore
          hash[type] ||= []
          hash[type] << input_file
        end
      end
      hash.sort_by { |t, f| input_file_type_order.index(t) || input_file_type_order.length }
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

    def make_navigator
      if @navigator_items
        @navigator = Navigator.new
        @navigator.items = @navigator_items.map do |uri, title|
          Navigator::Item.new(uri: uri, title: title)
        end
      end
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

    def load_schemas
      DefaultSchemaTypes.merge(@schema_types).each do |type, file|
        ;;warn "loading #{type} schema from #{file}"
        @schemas[type] = Nokogiri::XML::Schema(file.open) { |c| c.strict.nonet }
      end
    end

    def build_file_types
      @file_types = {}
      FileTypes.each do |type, mime_types|
        mime_types.each do |mime_type|
          MIME::Types[mime_type].each do |t|
            @file_types[t.content_type] = type
          end
        end
      end
    end

    def build_resource_classes
      @resource_classes = Hash[
        (DefaultResourceClasses + @resource_classes).map { |rc| [rc.type, rc] }
      ]
    end

    def publish(uri, **options)
      uri = Addressable::URI.parse(uri)
      command = case uri.scheme
      when 'rsync'
        build_rsync_command(uri, **options)
      when 'ftp'
        build_ftp_command(uri, **options)
      else
        raise "Unknown publishing destination scheme: #{uri}"
      end
      warn "* #{command.compact.join(' ')}"
      system(*command.compact)
    end

    def build_rsync_command(uri, dry_run: false, verbose: false, delete: true)
      [
        'rsync',
        '--archive',
        '--progress',
        (dry_run ? '--dry-run' : nil),
        (delete ? '--delete-after' : nil),
        (verbose ? '--verbose' : nil),
        @output_dir.to_s + '/',
        uri.to_s,
      ]
    end

    def build_ftp_command(uri, dry_run: false, verbose: false, delete: true)
      commands =  [
        %w{debug 5},
        %w{set cmd:fail-exit yes},
        %w{set ssl:verify-certificate no},
        %w{set ftp:ssl-allow no},
        ['lcd', @output_dir],
        ['open', uri],
        [
          'mirror',
          (verbose ? '--verbose=3' : nil),
          '--reverse',
          (dry_run ? '--dry-run' : nil),
          (delete ? '--delete' : nil),
          '--no-perms',
          '--no-umask',
          '--exclude-glob', '.htaccess',
          '--exclude-glob', 'cgi-bin/',
          '--exclude-glob', 'php.ini',
        ].compact
      ]
      cmd_file = Path.new('/tmp/lftp.cmd')
      cmd_file.open('w') do |out|
        out.puts(commands.map { |c| c.map(&:to_s).join(' ') }.join(";\n"))
      end
      [
        'lftp',
        '-f',
        cmd_file.to_s,
      ]
    end

  end

end
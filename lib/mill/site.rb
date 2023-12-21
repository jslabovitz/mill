module Mill

  class Site

    attr_reader   :dir
    attr_reader   :input_dir
    attr_reader   :output_dir
    attr_reader   :code_dir
    attr_accessor :site_rsync
    attr_accessor :site_title
    attr_reader   :site_uri
    attr_reader   :site_email
    attr_reader   :site_control_date
    attr_reader   :html_version
    attr_accessor :feed_resource
    attr_accessor :sitemap_resource
    attr_accessor :robots_resource
    attr_accessor :make_error
    attr_accessor :make_feed
    attr_accessor :make_sitemap
    attr_accessor :make_robots
    attr_accessor :allow_robots
    attr_accessor :redirects

    DefaultParams = {
      dir: '.',
      input_dir: 'content',
      output_dir: 'public_html',
      code_dir: 'code',
      site_uri: 'http://localhost',
      html_version: :html5,
      make_error: true,
      make_feed: true,
      make_sitemap: true,
      make_robots: true,
      allow_robots: true,
    }

    include SetParams

    def self.load(dir=nil)
      params = DefaultParams.dup
      params[:dir] = Path.new(dir || params[:dir])
      [:input_dir, :output_dir, :code_dir].each do |key|
        params[key] = params[:dir] / params[key]
      end
      load_yaml(params)
      klass = load_code(params) || self
      klass.new(params)
    end

    def self.load_yaml(params)
      if (yaml_file = ENV['MILL_CONFIG'])
        yaml_file = Path.new(yaml_file).expand_path
      else
        yaml_file = params[:dir] / 'mill.yaml'
      end
      raise Error, "Config file does not exist: #{yaml_file}" unless yaml_file.exist?
      yaml = YAML.load_file(yaml_file, permitted_classes: [Date, Symbol])
      params.update(yaml.map { |k, v| [k.to_sym, v] }.to_h)
    end

    def self.load_code(params)
      if (site_file = params[:dir] / params[:code_dir] / 'site.rb').exist?
        Kernel.require(site_file.expand_path.without_extension.to_s)
        site_classes = subclasses(self)
        raise Error, "More than one Site class defined" if site_classes.length > 1
        site_classes.first
      end
    end

    def self.subclasses(klass)
      ObjectSpace.each_object(Class).select { |c| c < klass }
    end

    def initialize(params={})
      super
      @archive = Archive.new
      @redirects = {}
      MIME::Types.add(MIME::Type.new(['text/textile', %w[textile]])) unless MIME::Types['text/textile']
      make_file_types
    end

    def dir=(d)
      @dir = d.kind_of?(Path) ? d : Path.new(d)
    end

    def input_dir=(d)
      @input_dir = @dir / d
    end

    def output_dir=(d)
      @output_dir = @dir / d
    end

    def code_dir=(d)
      @code_dir = @dir / d
    end

    def site_uri=(uri)
      @site_uri = Addressable::URI.parse(uri)
    end

    def site_email=(uri)
      @site_email = Addressable::URI.parse(uri)
    end

    def site_control_date=(date)
      @site_control_date = date.kind_of?(Date) ? date : Date.parse(date)
    end

    def html_version=(version)
      @html_version = version.to_sym
    end

    def make_file_types
      @file_types = {}
      Resource.subclasses.each do |resource_class|
        resource_class.const_get(:FileTypes).each do |type|
          @file_types[type] = resource_class
        end
      end
    end

    def add_resource(resource)
      # ;;warn "adding #{resource.class} as #{resource.path}"
      resource.site = self
      resource.load
      @archive << resource
    end

    def find_resource(path)
      @archive[path]
    end

    def root_resource
      @archive['/']
    end

    def tag_uri
      'tag:%s:' % [
        [
          @site_uri.host.downcase,
          @site_control_date
        ].join(','),
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
      advertised_resources
    end

    def sitemap_resources
      advertised_resources
    end

    def advertised_resources
      @archive.select(&:advertise?).sort_by(&:date)
    end

    def select_resources(*args)
      @archive.select(*args)
    end

    def print_tree(node=nil, level=0)
      unless node
        load_resources
        node = @documents_tree
      end
      if node.is_root?
        print '*'
      else
        print "\t" * level
      end
      print " #{node.name.inspect}"
      print " <#{node.content&.path}>"
      print " (#{node.children.length} children)" if node.has_children?
      puts
      node.children { |child| print_tree(child, level + 1) }
    end

    def list
      load_resources
      @archive.select.each do |resource|
        resource.list
        puts
      end
    end

    def print_file_types
      @file_types.sort.each do |type, klass|
        puts '%-40s %s' % [type, klass]
      end
    end

    def build
      load_resources
      convert_resources
      make_documents_tree
      build_resources
      check
      save_resources
    end

    def load_resources
      add_files
      add_redirects
      add_error if @make_error
      add_feed if @make_feed
      add_sitemap if @make_sitemap
      add_robots if @make_robots
    end

    def make_documents_tree
      @documents_tree = Tree::TreeNode.new('')
      @archive.select(&:advertise?).each do |resource|
        node = @documents_tree
        resource.path.split('/').reject(&:empty?).each do |component|
          node = node[component] || (node << Tree::TreeNode.new(component))
        end
        resource.node = node
        node.content = resource
      end
    end

    def build_resources
      @archive.each do |resource|
        # ;;warn "#{resource.path}: building"
        resource.build
      end
    end

    def convert_resources
      @archive.select { |r| r.respond_to?(:convert) }.each do |resource|
        new_resource = resource.convert
        @archive.delete(resource)
        if new_resource
          new_resource.load
          add_resource(new_resource)
        end
      end
    end

    def save_resources
      clean
      @output_dir.mkpath
      @archive.each do |resource|
        # ;;warn "#{resource.path}: saving"
        resource.save
      end
    end

    def clean
      if @output_dir.exist?
        @output_dir.children.reject { |p| p.basename.to_s == '.git' }.each do |path|
          path.rm_rf
        end
      end
    end

    def check(external: false)
      build if @archive.empty?
      @archive.select(Resource::Document).each do |resource|
        resource.links.each do |link|
          begin
            check_uri(link, external: external)
          rescue Error => e
            warn "#{resource.path}: #{e}"
          end
        end
      end
    end

    def snapshot
      @output_dir.chdir do
        system('git',
          'init') unless Path.new('.git').exist?
        system('git',
          'add',
          '.')
        system('git',
          'commit',
          '-a',
          '-m',
          'Update.')
      end
    end

    def diff
      @output_dir.chdir do
        system('git',
          'diff')
      end
    end

    def upload
      raise "site_rsync not defined" unless @site_rsync
      system('rsync',
        '--progress',
        '--verbose',
        '--archive',
        # '--append-verify',
        '--exclude=.git',
        '--delete-after',
        @output_dir.to_s,
        @site_rsync)
    end

    def resource_class_for_file(file)
      types = MIME::Types.of(file.to_s)
      content_type = types.last&.content_type
      if content_type && (klass = resource_class_for_type(content_type))
        klass
      else
        raise Error, "Unknown file type: #{file.to_s.inspect} (#{types.join(', ')})"
      end
    end

    def resource_class_for_type(type)
      @file_types[type]
    end

    private

    def add_files
      raise Error, "Input directory not found: #{@input_dir}" unless @input_dir.exist?
      @input_dir.find do |input_file|
        if input_file.basename.to_s[0] == '.'
          Find.prune
        elsif input_file.basename.to_s == "Icon\r"
          # skip macOS garbage file
        elsif input_file.directory?
          # skip directories
        else (klass = resource_class_for_file(input_file))
          resource = klass.new(input: input_file, path: '/' + input_file.relative_to(@input_dir).to_s)
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
        hidden: true,
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
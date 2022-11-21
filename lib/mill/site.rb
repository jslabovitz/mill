module Mill

  class Site

    attr_accessor :dir
    attr_accessor :input_dir
    attr_accessor :output_dir
    attr_accessor :code_dir
    attr_accessor :site_rsync
    attr_accessor :site_title
    attr_accessor :site_uri
    attr_accessor :site_email
    attr_accessor :site_control_date
    attr_accessor :html_version
    attr_accessor :feed_resource
    attr_accessor :sitemap_resource
    attr_accessor :robots_resource
    attr_accessor :shorten_uris
    attr_accessor :combine_sections
    attr_accessor :modes
    attr_accessor :make_feed
    attr_accessor :make_sitemap
    attr_accessor :make_robots
    attr_accessor :allow_robots
    attr_accessor :htpasswd_file
    attr_accessor :navigator
    attr_accessor :redirects
    attr_accessor :resources

    DefaultParams = {
      dir: '.',
      input_dir: 'content',
      output_dir: 'public_html',
      code_dir: 'code',
      site_uri: 'http://localhost',
      html_version: :html4,
      shorten_uris: true,
      make_feed: true,
      make_sitemap: true,
      make_robots: true,
      allow_robots: true,
      modes: [:html],
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
      yaml_file = params[:dir] / 'mill.yaml'
      if yaml_file.exist?
        yaml = YAML.load_file(yaml_file, permitted_classes: [Date, Symbol])
        params.update(yaml.map { |k, v| [k.to_sym, v] }.to_h)
      end
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
      @redirects = {}
      super
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

    def htpasswd_file=(file)
      @htpasswd_file = Path.new(file)
    end

    def modes=(modes)
      @modes = modes.map(&:to_sym)
    end

    def build_file_types
      @file_types = {}
      self.class.subclasses(Resource).each do |resource_class|
        resource_class.const_get(:FileTypes).each do |type|
          @file_types[type] = resource_class
        end
      end
    end

    def add_resource(resource)
      raise "Must assign resource to site" unless resource.site
      @resources[resource.path] = resource
      node = @resources_tree
      resource.path.split('/').reject(&:empty?).each do |component|
        node = node[component] || (node << Tree::TreeNode.new(component))
      end
      resource.node = node
      node.content = resource
      # ;;warn "added #{resource} as #{resource.path}"
    end

    def find_resource(path)
      path = path.path if path.kind_of?(Addressable::URI)
      @resources[path] || @resources[path + '/']
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

    def feed_author_name
      @site_title
    end

    def feed_author_uri
      @site_uri
    end

    def feed_author_email
      @site_email
    end

    def select_resources(selector=nil, &block)
      if block_given?
        @resources.values.select(&block)
      elsif selector.kind_of?(Class)
        @resources.values.select { |r| r.kind_of?(selector) }
      elsif selector
        @resources.values.select(selector)
      else
        @resources.values
      end
    end

    def feed_resources
      public_resources.sort_by(&:date)
    end

    def public_resources
      select_resources(&:public?)
    end

    def redirect_resources
      select_resources(&:redirect?)
    end

    def text_resources
      select_resources(&:text?)
    end

    def make
      build
      save
    end

    def print_tree(node=nil, level=0)
      node ||= @resources_tree
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

    ListKeys = {
      path:         :to_s,
      input_file:   :to_s,
      output_file:  :to_s,
      date:         :to_s,
      public:       :to_s,
      class:        :to_s,
      content:      proc { |r| r.content ? ('%s (%dKB)' % [r.content.class, (r.content.to_s.length / 1024.0).ceil]) : nil },
      parent:       proc { |r| r.parent&.path },
      siblings:     proc { |r| r.siblings.map(&:path) },
      children:     proc { |r| r.children.map(&:path) },
    }

    def list
      build
      width = ListKeys.keys.map(&:length).max
      select_resources.each do |resource|
        ListKeys.each do |key, converter|
          value = resource.send(key)
          value = case converter
          when nil
            value
          when Symbol
            value.send(converter)
          when Proc
            converter.call(resource)
          else
            raise
          end
          print '%*s: ' % [width, key]
          case value
          when Array
            if value.empty?
              puts '-'
            else
              value.each_with_index do |v, i|
                print '%*s  ' % [width, ''] if i > 0
                puts (v.nil? ? '-' : v)
              end
            end
          else
            puts (value.nil? ? '-' : value)
          end
        end
        puts
      end
      puts
    end

    def build
      build_file_types
      import_resources
      load_resources
      build_resources
    end

    def import_resources
      @resources = {}
      @resources_tree = Tree::TreeNode.new('')
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
        # ;;warn "#{resource.path}: loading"
        resource.load
      end
    end

    def build_resources
      on_each_resource do |resource|
        # ;;warn "#{resource.path}: building"
        resource.build
      end
    end

    def save
      clean
      @output_dir.mkpath
      on_each_resource do |resource|
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

    def check
      build
      checker = WebChecker.new(site_uri: @site_uri, site_dir: @output_dir)
      checker.check
      checker.report
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

    def on_each_resource(&block)
      @resources.values.each do |resource|
        begin
          yield(resource)
        rescue Error => e
          raise e, "#{resource.input_file || '-'} (#{resource.path}): #{e}"
        end
      end
    end

    private

    def resource_class_for_file(file)
      type = MIME::Types.of(file.to_s).first
      if type && (klass = @file_types[type.content_type])
        klass
      else
        raise Error, "Unknown file type: #{file.to_s.inspect} (#{MIME::Types.of(file.to_s).join(', ')})"
      end
    end

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
          resource = klass.new(
            input_file: input_file,
            output_file: @output_dir / input_file.relative_to(@input_dir),
            site: self)
          add_resource(resource)
        end
      end
    end

    def add_feed
      @feed_resource = Resource::Feed.new(
        output_file: @output_dir / 'feed.xml',
        site: self)
      add_resource(@feed_resource)
    end

    def add_sitemap
      @sitemap_resource = Resource::Sitemap.new(
        output_file: @output_dir / 'sitemap.xml',
        site: self)
      add_resource(@sitemap_resource)
    end

    def add_robots
      @robots_resource = Resource::Robots.new(
        output_file: @output_dir / 'robots.txt',
        site: self)
      add_resource(@robots_resource)
    end

    def add_redirects
      if @redirects
        @redirects.each do |from, to|
          output_file = @output_dir / Path.new(from).relative_to('/')
          resource = Resource::Redirect.new(
            output_file: output_file,
            redirect_uri: to,
            site: self)
          add_resource(resource)
        end
      end
    end

    def add_google_site_verification
      resource = Resource::GoogleSiteVerification.new(
        output_file: (@output_dir / @google_site_verification).add_extension('.html'),
        key: @google_site_verification,
        site: self)
      add_resource(resource)
    end

    def add_htpasswd
      resource = Resource.new(
        input_file: @htpasswd_file,
        output_file: @output_dir / '.htpasswd',
        site: self)
      add_resource(resource)
    end

  end

end
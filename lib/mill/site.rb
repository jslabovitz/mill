module Mill

  class Site

    attr_accessor :input_dir
    attr_accessor :output_dir
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
                   site_rsync: nil,
                   site_title: nil,
                   site_uri: 'http://localhost',
                   site_email: nil,
                   site_control_date: Date.today.to_s,
                   html_version: :html4,
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
      @site_rsync = site_rsync
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

      @resources = {}
      @resources_tree = Tree::TreeNode.new('')
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
      else
        @resources.values.select(selector)
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
        elsif input_file.directory?
          # skip
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
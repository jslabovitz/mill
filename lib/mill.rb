require 'addressable'
require 'image_size'
require 'kramdown'
require 'mime/types'
require 'nokogiri'
require 'path'
require 'pp'
require 'RedCloth'
require 'rubypants'
require 'time'
require 'tidy_ffi'
require 'term/ansicolor'

require 'mill/file_types'
require 'mill/html_helpers'
require 'mill/navigator'
require 'mill/resource'
require 'mill/resources/feed'
require 'mill/resources/generic'
require 'mill/resources/image'
require 'mill/resources/redirect'
require 'mill/resources/robots'
require 'mill/resources/sitemap'
require 'mill/resources/text'
require 'mill/version'

class Mill

  attr_accessor :input_dir
  attr_accessor :output_dir
  attr_accessor :site_title
  attr_accessor :site_uri
  attr_accessor :site_email
  attr_accessor :site_control_date
  attr_accessor :feed_resource
  attr_accessor :sitemap_resource
  attr_accessor :robots_resource
  attr_accessor :ssh_location
  attr_accessor :beta_ssh_location
  attr_accessor :resources
  attr_accessor :shorten_uris
  attr_accessor :navigator
  attr_accessor :navigator_items
  attr_accessor :resource_classes
  attr_accessor :schema_types
  attr_accessor :redirects
  attr_accessor :input_file_type_order
  attr_accessor :link_elem_attrs

  DefaultResourceClasses = [
    Resource::Text,
    Resource::Image,
    Resource::Generic,
  ]

  SchemasDir = Path.new(__FILE__).dirname / 'mill' / 'schemas'

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
    @link_elem_attrs = %w{
      img/@src
      script/@src
      a/@href
      link/@href
      stylesheet/@href
    }
    params.each { |k, v| send("#{k}=", v) }
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
    begin
      # ;;warn "loading #{resource.class.type} resource #{resource.uri} as #{resource.class}"
      resource.load
    rescue => e
      warn "Failed to load resource #{resource.uri} (#{resource.class}): #{e}"
      raise
    end
    @resources << resource
  end

  def update_resource(resource)
    @resources_by_uri[resource.uri] = resource
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

  def clean
    @output_dir.rmtree if @output_dir.exist?
    @output_dir.mkpath
  end

  def load
    warn "loading resources..."
    build_file_types
    build_resource_classes
    build_schemas
    load_files
    load_others
  end

  def load_others
    make_redirects
    make_feed
    make_sitemap
    make_robots
    make_navigator
  end

  def build
    warn "building #{@resources.length} resources..."
    @resources.each do |resource|
      begin
        resource.build
      rescue => e
        warn "Failed to build resource #{resource.uri}: #{e}"
        raise
      end
    end
  end

  def publish(mode=:final)
    location = case mode
               when :final
                 @ssh_location
               when :beta
                 @beta_ssh_location
               else
                 raise "Unknown publish mode: #{mode.inspect}"
               end
    raise "Must specify SSH location" unless location
    system('rsync',
      # '--dry-run',
      '--archive',
      '--delete-after',
      '--progress',
      # '--verbose',
      @output_dir.to_s + '/',
      location,
    )
  end

  def server
    SimpleServer.run!(
      root: @output_dir,
      multihosting: false,
    )
  end

  private

  def load_files
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

  def make_feed
    @feed_resource = Resource::Feed.new(
      output_file: @output_dir / 'feed.xml')
    add_resource(@feed_resource)
  end

  def make_sitemap
    @sitemap_resource = Resource::Sitemap.new(
      output_file: @output_dir / 'sitemap.xml')
    add_resource(@sitemap_resource)
  end

  def make_robots
    @robots_resource = Resource::Robots.new(
      output_file: @output_dir / 'robots.txt')
    add_resource(@robots_resource)
  end

  def make_navigator
    if @navigator_items
      @navigator = Navigator.new
      @navigator.items = @navigator_items.map do |uri, title|
        uri = Addressable::URI.parse(uri)
        if title.nil? && uri.relative?
          resource = find_resource(uri) or raise "Can't find navigation resource for URI #{uri}"
          title = resource.title
        end
        Navigator::Item.new(uri: uri, title: title)
      end
    end
  end

  def make_redirects
    return unless @redirects
    @redirects.each do |from, to|
      output_file = @output_dir / Path.new(from).relative_to('/')
      resource = Resource::Redirect.new(
        output_file: output_file,
        redirect_uri: to)
      add_resource(resource)
    end
  end

  def build_schemas
    DefaultSchemaTypes.merge(@schema_types).each do |type, file|
      ;;warn "loading schema #{type} from #{file}"
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

end

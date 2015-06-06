require 'addressable/uri'
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
  attr_accessor :resources
  attr_accessor :shorten_uris
  attr_accessor :navigator
  attr_accessor :navigator_items
  attr_accessor :resource_classes

  DefaultResourceClasses = [
    Resource::Text,
    Resource::Image,
    Resource::Generic,
  ]

  def initialize(params={})
    @resource_classes = {}
    @resources = []
    @resources_by_uri = {}
    @shorten_uris = true
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
    MIME::Types.of(file.to_s).each do |mime_type|
      if (type = @file_types[mime_type.content_type])
        return type
      end
    end
    nil
  end

  def add_resource(resource)
    resource.mill = self
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
    Addressable::URI.parse("mailto:#{@site_email}")
  end

  def public_resources
    @resources.select(&:public)
  end

  def clean
    @output_dir.rmtree if @output_dir.exist?
    @output_dir.mkpath
  end

  def load
    build_file_types
    build_resource_classes
    load_files
    load_others
  end

  def load_others
    make_feed
    make_sitemap
    make_robots
    make_navigator
  end

  def process
    @resources.reject { |r| r.processed? }.each do |resource|
      begin
        resource.process
      rescue => e
        warn "failed to process #{resource.uri} (#{resource.class}): #{e}"
        raise
      end
    end
  end

  def build
    @resources.reject { |r| r.built? }.each do |resource|
      begin
        resource.build
      rescue => e
        warn "failed to build #{resource.uri} (#{resource.class}): #{e}"
        raise
      end
    end
  end

  def publish
    raise "Must specify SSH location" unless @ssh_location
    system('rsync',
      # '--dry-run',
      '--archive',
      '--delete-after',
      '--progress',
      # '--verbose',
      @output_dir.to_s + '/',
      @ssh_location,
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
    raise "Input path not found: #{@input_dir}" unless @input_dir.exist?
    @input_dir.find do |file_path|
      input_file = (@input_dir / file_path).expand_path
      output_file = (@output_dir / file_path.relative_to(@input_dir)).expand_path
      next if input_file.directory? || input_file.basename.to_s[0] == '.'
      type = file_type(input_file) or raise "Can't determine file type of #{input_file}"
      resource_class = @resource_classes[type] or raise "No resource class for #{input_file}"
      resource = resource_class.new(
        input_file: input_file,
        output_file: output_file)
      add_resource(resource)
    end
    @resources.reject { |r| r.loaded? }.each do |resource|
      begin
        resource.load
      rescue => e
        warn "failed to load #{resource.uri} (#{resource.class}): #{e}"
        raise
      end
    end
  end

  def make_feed
    @feed_resource = Resource::Feed.new(
      output_file: @output_dir / 'feed.xml')
    add_resource(@feed_resource)
    @feed_resource.load
  end

  def make_sitemap
    @sitemap_resource = Resource::Sitemap.new(
      output_file: @output_dir / 'sitemap.xml')
    add_resource(@sitemap_resource)
    @sitemap_resource.load
  end

  def make_robots
    @robots_resource = Resource::Robots.new(
      output_file: @output_dir / 'robots.txt')
    add_resource(@robots_resource)
    @robots_resource.load
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
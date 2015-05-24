require 'addressable/uri'
require 'image_size'
require 'kramdown'
require 'mime/types'
require 'nokogiri'
require 'path'
require 'pp'
require 'RedCloth'
require 'time'
require 'tidy_ffi'
require 'term/ansicolor'

require 'mill/file_types'
require 'mill/html_helpers'
require 'mill/importer'
require 'mill/importers/generic'
require 'mill/importers/html'
require 'mill/importers/image'
require 'mill/importers/text'
require 'mill/navigator'
require 'mill/resource'
require 'mill/resources/feed'
require 'mill/resources/generic'
require 'mill/resources/html'
require 'mill/resources/image'
require 'mill/resources/redirect'
require 'mill/resources/robots'
require 'mill/resources/sitemap'
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

  DefaultImporterClasses = {
    html: Importers::HTML,
    text: Importers::Text,
    image: Importers::Image,
    stylesheet: Importers::Generic,
    font: Importers::Generic,
    javascript: Importers::Generic,
    pdf: Importers::Generic,
  }

  DefaultResourceClasses = {
    html: Resource::HTML,
    image: Resource::Image,
    stylesheet: Resource::Generic,
    font: Resource::Generic,
    javascript: Resource::Generic,
    pdf: Resource::Generic,
  }

  def self.default_params
    {}
  end

  def initialize(params={})
    @importer_classes = {}
    @resource_classes = {}
    @resources = {}
    @shorten_uris = true
    @navigator = Navigator.new
    build_file_types
    set_importer_classes(DefaultImporterClasses)
    set_resource_classes(DefaultResourceClasses)
    self.class.default_params.merge(params).each { |k, v| send("#{k}=", v) }
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

  def build_file_types
    @file_types = {}
    FileTypes.each do |file_type, mime_types|
      mime_types.each do |mime_type|
        MIME::Types[mime_type].each do |t|
          @file_types[t.content_type] = file_type
        end
      end
    end
  end

  def file_type(file)
    MIME::Types.of(file.to_s).each do |mime_type|
      if (file_type = @file_types[mime_type.content_type])
        return file_type
      end
    end
    nil
  end

  def set_importer_classes(info)
    @importer_classes.merge!(info)
  end

  def importer_class_for_file(file)
    type = file_type(file) or raise "Can't determine file type of #{file}"
    @importer_classes[type]
  end

  def set_resource_classes(info)
    @resource_classes.merge!(info)
  end

  def resource_class_for_file(file)
    type = file_type(file) or raise "Can't determine file type of #{file}"
    @resource_classes[type]
  end

  def add_resource(resource)
    @resources[resource.uri] = resource
    # ;;warn "%s: adding as %s from %s" % [
    #   resource.uri,
    #   resource.class,
    #   resource.input_file ? resource.input_file.relative_to(@input_dir) : '(dynamic)',
    # ]
  end

  def find_resource(uri)
    uri = Addressable::URI.parse(uri)
    resource = @resources[uri]
    if resource.nil? && @shorten_uris
      uri.path = uri.path.sub(%r{\.html$}, '')
      resource = @resources[uri]
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
    @resources.values.select(&:public)
  end

  def clean
    @output_dir.rmtree if @output_dir.exist?
    @output_dir.mkpath
  end

  def load
    raise "Input path not found: #{@input_dir}" unless @input_dir.exist?
    import_files
    make_feed
    make_sitemap
    make_robots
  end

  def import_files
    @input_dir.find do |file_path|
      input_file = (@input_dir / file_path).expand_path
      output_file = (@output_dir / file_path.relative_to(@input_dir)).expand_path
      if input_file.directory?
        next
      elsif input_file.basename.to_s[0] == '.'
        next
      elsif (importer_class = importer_class_for_file(input_file))
        importer = importer_class.new(
          input_file: input_file,
          output_file: output_file,
          mill: self)
        importer.import
      else
        warn "No importer for #{input_file} -- ignoring"
      end
    end
  end

  def make_feed
    @feed_resource = Resource::Feed.new(
      output_file: @output_dir / 'feed.xml',
      mill: self)
  end

  def make_sitemap
    @sitemap_resource = Resource::Sitemap.new(
      output_file: @output_dir / 'sitemap.xml',
      mill: self)
  end

  def make_robots
    @robots_resource = Resource::Robots.new(
      output_file: @output_dir / 'robots.txt',
      mill: self)
  end

  def process
    make_navigator
    @resources.values.reject(&:processed).each do |resource|
      # ;;warn "%s: processing" % [
      #   resource.uri,
      # ]
      resource.process
    end
  end

  def build
    @resources.values.each do |resource|
      # ;;warn "%s: building to %s" % [
      #   resource.uri,
      #   resource.output_file.relative_to(@output_dir),
      # ]
      resource.build
    end
  end

  def verify
    @resources.values.each do |resource|
      # ;;warn "%s: verifing %s" % [
      #   resource.uri,
      #   resource.output_file.relative_to(@output_dir),
      # ]
      resource.verify
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

  def make_navigator
    if @navigator_items
      @navigator.items = @navigator_items.map do |uri, title|
        resource = find_resource(uri) or raise "Can't find navigation resource for #{uri.inspect}"
        Navigator::Item.new(resource: resource, title: title || resource.title)
      end
    end
  end

end
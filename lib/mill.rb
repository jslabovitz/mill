require 'addressable/uri'
require 'image_size'
require 'kramdown'
require 'nokogiri'
require 'path'
require 'pp'
require 'time'
require 'tidy_ffi'
require 'term/ansicolor'

require 'mill/navigator'
require 'mill/resource'
require 'mill/resources/feed'
require 'mill/resources/generic'
require 'mill/resources/html'
require 'mill/resources/image'
require 'mill/resources/markdown'
require 'mill/resources/robots'
require 'mill/resources/sitemap'
require 'mill/version'

class Mill

  attr_accessor :input_dir
  attr_accessor :output_dir
  attr_accessor :site_title
  attr_accessor :site_uri
  attr_accessor :feed_resource
  attr_accessor :sitemap_resource
  attr_accessor :robots_resource
  attr_accessor :ssh_location
  attr_accessor :resources
  attr_accessor :shorten_uris
  attr_accessor :navigator

  def initialize(params={})
    @resources = {}
    @shorten_uris = true
    make_resource_classes
    params.each { |k, v| send("#{k}=", v) }
  end

  def self.resource_classes
    [
      Resource::Generic,
      Resource::HTML,
      Resource::Image,
      Resource::Markdown,
    ]
  end

  def make_resource_classes
    @resource_classes = {}
    self.class.resource_classes.each do |resource_class|
      resource_class.file_extensions.each do |file_extension|
        @resource_classes[file_extension] = resource_class
      end
    end
  end

  def input_dir=(path)
    @input_dir = Path.new(path).realpath
  end

  def output_dir=(path)
    @output_dir = Path.new(path).realpath
  end

  def site_uri=(uri)
    @site_uri = Addressable::URI.parse(uri)
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

  def <<(resource)
    add_resource(resource)
  end

  def [](uri)
    find_resource(uri)
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
    @input_dir.find do |input_file|
      input_file = Path.new(input_file).realpath
      next if input_file.directory? || input_file.basename.to_s[0] == '.'
      output_file = @output_dir / input_file.relative_to(@input_dir)
      resource_class = @resource_classes[input_file.extname.downcase] or raise "No resource class for #{input_file}"
      resource = resource_class.new(
        input_file: input_file,
        output_file: output_file,
        mill: self)
      resource.load
      add_resource(resource)
    end
    load_feed
    load_sitemap
    load_robots
  end

  def load_feed
    @feed_resource = Resource::Feed.new(
      output_file: @output_dir / 'feed.xml',
      mill: self)
    @feed_resource.load
    add_resource(@feed_resource)
  end

  def load_sitemap
    @sitemap_resource = Resource::Sitemap.new(
      output_file: @output_dir / 'sitemap.xml',
      mill: self)
    @sitemap_resource.load
    add_resource(@sitemap_resource)
  end

  def load_robots
    @robots_resource = Resource::Robots.new(
      output_file: @output_dir / 'robots.txt',
      mill: self)
    @robots_resource.load
    add_resource(@robots_resource)
  end

  def process
    @resources.values.each do |resource|
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

end
require 'kramdown'
require 'nokogiri'
require 'pp'
require 'webrick'
require 'image_size'
require 'path'
require 'logger'
require 'date'
require 'addressable/uri'
require 'hashstruct'
require 'rmagick'

require 'mill/version'

require 'mill/extensions/path'
require 'mill/extensions/string'
require 'mill/extensions/time'

require 'mill/file_type_mapper'
require 'mill/logging'
# require 'mill/feed'

require 'mill/resource'
require 'mill/resources/file'
require 'mill/resources/image'
require 'mill/resources/page'

require 'mill/server'
require 'mill/importer'

include Logging

class Mill

  attr_accessor :content_dir
  attr_accessor :site_dir
  attr_accessor :resources_dir
  attr_accessor :resources

  def initialize(params={})
    self.content_dir = 'content'
    self.resources_dir = 'resources'
    self.site_dir = 'site'
    @resources = []
    params.each { |k, v| send("#{k}=", v) }
  end

  def content_dir=(dir)
    @content_dir = Path.new(dir)
  end

  def resources_dir=(dir)
    @resources_dir = Path.new(dir)
  end

  def site_dir=(dir)
    @site_dir = Path.new(dir)
  end

  def import
    Importer.new(input_dir: @content_dir, output_dir: @resources_dir).import
  end

  def build
    log.debug "building from #{@resources_dir} to #{@site_dir}"
    load_resources
    render_resources
  end

  def load_resources
    return unless @resources_dir && @resources_dir.exist?
    log.debug(1) { "loading files from #{@resources_dir}" }
    @resources_dir.find do |file|
      next if file.hidden? || file.directory? || file.extname != '.xml'
      log.debug(2) { "loading file #{file}" }
      resource = Resource.load(file, mill: self)
      log.debug(3) { "loaded resource: #{resource.inspect}" }
      @resources << resource
    end
  end

  def [](path)
    path = Path.new(path)
    @resources.find { |r| r.path == path } or raise "Can't find resource for path #{path.inspect}"
  end

  def render_resources
    log.debug(1) { "rendering resources"}
    @resources.each do |resource|
      log.debug(2) { "rendering resource #{resource.inspect}" }
      resource.render(output_dir: @site_dir)
    end
  end

  def clean
    [@resources_dir, @site_dir].each do |dir|
      if dir.exist?
        log.info "Cleaning #{dir}"
        dir.rmtree
      end
    end
  end

  def server
    Server.run!(public_dir: @site_dir)
  end

end
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

require 'mill/logging'
require 'mill/resource'
require 'mill/processor'
require 'mill/server'
# require 'mill/feed'

require 'mill/resources/generic'
require 'mill/resources/html'
require 'mill/resources/image'
require 'mill/resources/markdown'

include Logging

class Mill

  FileTypes = {
    any:      '*',
    image:    [:jpeg, :tiff, :png, :ico, :gif],
    png:      '.png',
    ico:      '.ico',
    gif:      '.gif',
    jpeg:     %w{.jpg .jpeg},
    tiff:     %w{.tif .tiff},
    yaml:     '.yaml',
    html:     '.html',
    css:      '.css',
    js:       '.js',
    pdf:      '.pdf',
    markdown: %w{.md .mdown .markdown},
  }

  @@processor_specs = {}

  def self.build_type_tables
    @extensions_for_type = {}
    @type_for_extension = {}
    FileTypes.keys.each do |type|
      extensions = [lookup_type(type)].flatten
      @extensions_for_type[type] = extensions
      extensions.each do |extension|
        @type_for_extension[extension] = type
      end
    end
  end

  def self.lookup_type(type)
    case type
    when Symbol
      lookup_type(FileTypes[type])
    when String
      type
    when Array
      type.map { |t| lookup_type(t) }.flatten
    else
      raise "Unknown type: #{type.inspect}"
    end
  end

  build_type_tables

  def self.extensions_for_type(type)
    @extensions_for_type[type] or raise "Can't determine extensions for type #{type.inspect}"
  end

  def self.type_for_file(file)
    @type_for_extension[file.extname] or raise "Can't determine type for file #{file} (#{file.extname} =~ #{@type_for_extension.inspect}"
  end

  def self.process(name, &block)
    @@processor_specs[name] = block
  end

  ###

  attr_accessor :site_dir

  def initialize(params={})
    @site_dir = 'site'
    params.each { |k, v| send("#{k}=", v) }
  end

  def build_processors
    @processors = {}
    @@processor_specs.each do |name, proc|
      processor = Processor.new(name: name, mill: self)
      processor.instance_eval(&proc)
      @processors[name] = processor
    end
  end

  def processors_for_name(name=nil)
    if name
      processor = @processors[name] or raise "No processor for name #{name.inspect}"
      [processor]
    else
      @processors.values
    end
  end

  def build(name=nil)
    build_processors
    processors_for_name(name).each do |processor|
      processor.build
    end
  end

  def clean(name=nil)
    build_processors
    processors_for_name(name).each do |processor|
      processor.clean
    end
  end

  def server
    Server.run!(public_dir: @site_dir)
  end

  def resources_loaded(processor)
  end

end
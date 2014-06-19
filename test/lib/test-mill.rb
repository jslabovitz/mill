$LOAD_PATH.unshift 'lib'

require 'resource/html'
require 'resource/image'
require 'resource/markdown'

=begin

  a Mill
    has several independent Processors
    stores global settings
    runs each Processor on demand
    can clean up outputs of Processors

  a Processor
    has source (input) and destination (output) directories, containing files
    maintains a store of Resources
    knows how to map an input file to a Resource
    tells Resources to load, process, and save data
    loads all known Resources first
    then processes (as needed?)
    writes to output

  a Resource
    optionally has a source (input)
    optionally has data
    loads, processes, and saves data of a specific type (eg, image)
    knows about its parent processor
    is referred to by its path

  general principles:

    - if a resource requires another resource, that resource must have been loaded first
    - resources are loaded only from the input directory for the processor
    - resources are saved only to the output directory for the processor
    - resource types named in the 'process' directive are processed and saved; all others are only for reference

=end


class TestMill < Mill

  attr_accessor :max_image_size

  def initialize(params={})
    @max_image_size = 500
    super
  end

  process :images do
    input 'content'
    output 'tmp'
    process :image, TestMill::Resource::Image
  end

  process :markdown do
    input 'content'
    output 'tmp'
    process :markdown, TestMill::Resource::Markdown
  end

  process :html do
    input 'tmp'
    output 'site'
    process :image, TestMill::Resource::Image
    process :html, TestMill::Resource::HTML
  end

  process :static do
    input 'static'
    output 'site'
    process :any, Mill::Resource::Generic
  end

end
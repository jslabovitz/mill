require 'addressable'
require 'hashstruct'
require 'http'
require 'image_size'
require 'kramdown'
require 'mime/types'
require 'nokogiri'
require 'path'
require 'RedCloth'
require 'run-command'
require 'sassc'
require 'set_params'
require 'simple-builder'
require 'simple-command'
require 'simple-config'
require 'simple-printer'
require 'time'
require 'tree'

class Class

  def self.subclasses
    constants
      .map { |c| const_get(c) }
      .select { |c| c.kind_of?(Class) }
  end

end

require 'mill/command'
require 'mill/config'
require 'mill/error'
require 'mill/resource'
require 'mill/resources'
require 'mill/resources/blob'
require 'mill/resources/feed'
require 'mill/resources/image'
require 'mill/resources/markup'
require 'mill/resources/markdown'
require 'mill/resources/page'
require 'mill/resources/redirect'
require 'mill/resources/robots'
require 'mill/resources/sitemap'
require 'mill/resources/stylesheet'
require 'mill/resources/textile'
require 'mill/site'

Path.new(__FILE__).dirname.glob('mill/commands/*.rb').each { |p| require p }
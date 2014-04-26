require 'kramdown'
require 'hashstruct'
require 'nokogiri'
require 'pp'
require 'webrick'
require 'image_size'
require 'path'
require 'logger'
require 'uri'

require 'mill/version'

require 'mill/extensions/array'
require 'mill/extensions/path'

require 'mill/logging'
require 'mill/filter'
require 'mill/resource'
require 'mill/site'

require 'mill/filters/read_file'
require 'mill/filters/write_file'
require 'mill/filters/copy_file'
require 'mill/filters/decorate_html'
require 'mill/filters/markdown_to_html'
require 'mill/filters/parse_html'
require 'mill/filters/parse_markdown'
require 'mill/filters/add_image_sizes'
require 'mill/filters/add_external_link_targets'

include Logging
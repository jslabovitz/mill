# avoid annoying warnings
$VERBOSE = false
class Object
  def tainted?; false; end
end

require 'minitest/autorun'
require 'minitest/power_assert'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'mill'

module Mill

  class Test < Minitest::Test

    def setup
      @site = Site.load('test/site.yaml')
      @site.make
# ;;@site.print_tree
# ;;@site.list
# ;;binding.pry
      @root = @site.find_resource('/') or raise
      @a = @site.find_resource('/a') or raise
      @b = @site.find_resource('/b') or raise
      @ba = @site.find_resource('/b/ba') or raise
      @bb = @site.find_resource('/b/bb') or raise
    end

    AuxiliaryPaths = %w{
      /feed.xml
      /sitemap.xml
      /robots.txt
    }

    def test_has_index
      assert { @root }
    end

    def test_children
      children = @root.children.reject { |c| AuxiliaryPaths.include?(c.path) }
      assert { children == [@a, @b] }
      assert { @a.children.empty? }
    end

    def test_parent
      assert { @a.parent == @root }
      assert { @b.parent == @root }
      assert { @ba.parent == @b }
      assert { @bb.parent == @b }
    end

    def test_siblings
      siblings = @root.siblings.reject { |c| AuxiliaryPaths.include?(c.path) }
      a_siblings = @a.siblings.reject { |c| AuxiliaryPaths.include?(c.path) }
      ba_siblings = @ba.siblings.reject { |c| AuxiliaryPaths.include?(c.path) }
      assert { siblings.empty? }
      assert { a_siblings == [@b] }
      assert { ba_siblings == [@bb] }
    end

  end

end
$VERBOSE = false

require 'minitest/autorun'
require 'minitest/power_assert'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'mill'

module Mill

  class Test < Minitest::Test

    def setup
      @site = Site.new(
        input_dir: 'test/content',
        output_dir: 'test/output',
        site_title: 'Test',
        site_uri: 'http://test.test',
        html_version: :html5,
      )
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

    def test_has_index
      assert { @root }
    end

    def test_children
      assert { @root.children == [@a, @b] }
      assert { @a.children.empty? }
    end

    def test_parent
      assert { @a.parent == @root }
      assert { @b.parent == @root }
      assert { @ba.parent == @b }
      assert { @bb.parent == @b }
    end

    def test_siblings
      assert { @root.siblings.empty? }
      assert { @a.siblings == [@b] }
      assert { @ba.siblings == [@bb] }
    end

  end

end
require 'minitest/autorun'
require 'minitest/power_assert'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'mill'

module Mill

  class Test < Minitest::Test

    def setup
      @site = Site.load('test')
      @site.make
# ;;@site.print_tree
# ;;@site.list
      @root = @site.find_resource('/')
      @a = @site.find_resource('/a')
      @b = @site.find_resource('/b')
      @ba = @site.find_resource('/b/ba')
      @bb = @site.find_resource('/b/bb')
      @c = @site.find_resource('/c')
      @d = @site.find_resource('/d')
    end

    def test_has_index
      assert { @root }
    end

    def test_resources
      assert { @a }
      assert { @b }
      assert { @ba }
      assert { @bb }
      assert { @c }
      assert { @d }
    end

    def test_hidden
      assert { @c.hidden? }
    end

    def test_draft
      assert { @d.draft? }
    end

    def test_children
      children = @root.children
      assert { children == [@a, @b, @c, @d] }
      assert { @a.children.empty? }
    end

    def test_parent
      assert { @a.parent == @root }
      assert { @b.parent == @root }
      assert { @ba.parent == @b }
      assert { @bb.parent == @b }
    end

    def test_siblings
      root_siblings = @root.siblings
      a_siblings = @a.siblings
      ba_siblings = @ba.siblings
      assert { root_siblings.empty? }
      assert { a_siblings == [@b, @c, @d] }
      assert { ba_siblings == [@bb] }
    end

  end

end
module Mill

  class Resources

    include SetParams

    def initialize(params={})
      super
      @dictionary = {}
      @tree = Tree::TreeNode.new('')
    end

    def <<(resource)
      @dictionary[resource.path] = resource
      if resource.advertise?
        node = find_or_create_node(resource.path)
        resource.node = node
        node.content = resource
      end
    end

    def empty?
      @dictionary.empty?
    end

    def [](path)
      path = path.path if path.kind_of?(Addressable::URI)
      @dictionary[path] || @dictionary[path + '/']
    end

    def each(&block)
      @dictionary.values.each(&block)
    end

    def select(&block)
      @dictionary.values.select(&block)
    end

    def of_class(klass)
      @dictionary.values.select { |r| r.kind_of?(klass) }
    end

    def delete(resource)
      @dictionary.delete(resource.path) or raise Error, "No resource with path #{resource.path.inspect}"
      if (node = find_node(resource.path))
        node.delete
      end
    end

    def find_node(path)
      node = @tree
      path_components(path).each do |component|
        node = node[component] or return nil
      end
      node
    end

    def find_or_create_node(path)
      node = @tree
      path_components(path).each do |component|
        node = node[component] || (node << Tree::TreeNode.new(component))
      end
      node
    end

    def path_components(path)
      path.split('/').reject(&:empty?)
    end

    def print_tree
      print_node(@tree)
    end

    def print_node(node, level=0)
      if node.is_root?
        print '*'
      else
        print "\t" * level
      end
      print " #{node.name.inspect}"
      print " <#{node.content&.path}>"
      print " (#{node.children.length} children)" if node.has_children?
      puts
      node.children { |child| print_node(child, level + 1) }
    end

  end

end
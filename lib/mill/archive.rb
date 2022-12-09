module Mill

  class Archive

    include SetParams

    def initialize(params={})
      super
      @resources = {}
    end

    def <<(resource)
      @resources[resource.path] = resource
    end

    def empty?
      @resources.empty?
    end

    def [](path)
      path = path.path if path.kind_of?(Addressable::URI)
      @resources[path] || @resources[path + '/']
    end

    def each(&block)
      @resources.values.each(&block)
    end

    def select(selector=nil, &block)
      resources = @resources.values
      resources.select! { |r| r.kind_of?(selector) } if selector
      resources.select!(&block) if block_given?
      resources
    end

  end

end
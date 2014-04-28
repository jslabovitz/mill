module Mill

  class Filter

    class SkipResource < Exception; end

    def process(resource)
    end

    def skip(msg=nil)
      raise SkipResource, msg
    end

  end

end
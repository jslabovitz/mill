class Mill

  class Navigator

    class Item

      attr_accessor :resource
      attr_accessor :title
      attr_accessor :state

      def initialize(params={})
        params.each { |k, v| send("#{k}=", v) }
      end

    end

    attr_accessor :items

    def initialize(params={})
      @items = []
      params.each { |k, v| send("#{k}=", v) }
    end

    def state_for_resource(resource, &block)
      states = @items.dup
      states.each { |s| s.state = :other }
      if (item = states.find { |s| s.resource.uri == resource.uri })
        item.state = :current
      else
        within_items = []
        states.each do |item|
          if resource.uri.path.start_with?(item.resource.uri.path)
            within_items << item
          end
        end
        if !within_items.empty?
          within_item = within_items.sort_by { |item| item.resource.uri.path.count('/') }.last
          within_item.state = :within
        end
      end
      states
    end

    def first_item
      @items.first
    end

    def last_item
      @items.last
    end

    def previous_item(resource)
      index = find_item_index_by_resource(resource)
      if index && index > 0
        @items[index - 1]
      else
        nil
      end
    end

    def next_item(resource)
      index = find_item_index_by_resource(resource)
      if index && index < @items.length - 1
        @items[index + 1]
      else
        nil
      end
    end

    def find_item_index_by_resource(resource)
      item = @items.find { |item| item.resource == resource }
      @items.index(item)
    end

  end

end
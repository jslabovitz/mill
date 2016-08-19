module Mill

  class Navigator

    class Item

      attr_accessor :uri
      attr_accessor :title

      def initialize(uri:, title: nil)
        @uri = Addressable::URI.parse(uri)
        @title = title
      end

    end

    attr_accessor :items

    def initialize(items: [])
      @items = items.map { |uri, title| Item.new(uri: uri, title: title) }
    end

    def item_states_for_uri(uri, &block)
      current_item = within_item = nil
      if (item = @items.find { |item| item.uri.relative? && item.uri == uri })
        current_item = item
      else
        within_item = @items.select do |item|
          item.uri.relative? && uri.path.start_with?(item.uri.path)
        end.sort_by do |item|
          item.uri.path.count('/')
        end.last
      end
      @items.each do |item|
        if item == current_item
          state = :current
        elsif item == within_item
          state = :within
        else
          state = :other
        end
        yield(state, item)
      end
    end

    def first_item
      @items.first
    end

    def last_item
      @items.last
    end

    def previous_item(uri)
      index = find_item_index_by_uri(uri)
      if index && index > 0
        @items[index - 1]
      else
        nil
      end
    end

    def next_item(uri)
      index = find_item_index_by_uri(uri)
      if index && index < @items.length - 1
        @items[index + 1]
      else
        nil
      end
    end

    def find_item_index_by_uri(uri)
      if (item = @items.find { |item| item.uri == uri })
        @items.index(item)
      end
    end

  end

end
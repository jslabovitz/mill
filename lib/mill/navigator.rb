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

    def initialize(items: [])
      @items = Hash[
        items.map do |uri, title|
          item = Item.new(uri: uri, title: title)
          [item.uri, item]
        end
      ]
    end

    def items
      @items.values
    end

    def first_item
      @items.values.first
    end

    def last_item
      @items.values.last
    end

    def previous_item(uri)
      if (item = @items[uri])
        i = @items.values.index(item)
        if i > 0
          return @items.values[i - 1]
        end
      end
      nil
    end

    def next_item(uri)
      if (item = @items[uri])
        i = @items.values.index(item)
        if i < @items.length - 1
          return @items.values[i + 1]
        end
      end
      nil
    end

  end

end
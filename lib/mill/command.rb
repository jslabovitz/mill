module Mill

  class Command < Simple::CommandParser::Command

    attr_accessor :dir

    def run(args)
      @site = Mill::Site.load(@dir || '.')
    end

  end

end
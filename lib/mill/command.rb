module Mill

  class Command < SimpleCommand::Command

    def run(args)
      @site = Mill::Site.load(@dir || '.')
    end

  end

end
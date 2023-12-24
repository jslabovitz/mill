module Mill

  class Command < SimpleCommand::Command

    def run(args)
      # dir = Path.new(@dir || '.')
      # config_file = dir / ConfigFileName
      # config = config_file.exist? ? BaseConfig.load(config_file) : BaseConfig.make
      @site = Mill::Site.load
    end

  end

end
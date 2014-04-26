module Logging

  def log
    @log ||= Logger.new(STDERR).tap do |logger|
      logger.level = ENV['LOG'] ? eval("Logger::#{ENV['LOG']}") : Logger::INFO
      logger.formatter = proc do |severity, timestamp, progname, msg|
        "%s%s\n" % [
          progname ? ("\t" * progname) : '',
          msg,
        ]
      end
    end
  end

end
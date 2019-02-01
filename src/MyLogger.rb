require 'logger'

class MyLogger
  
  def initialize
    @log = Logger.new( File.open( "#{ File.dirname(__FILE__) }/../log/dlnaify.log", "a") )
  end

  @@instance = MyLogger.new

  def self.instance
    return @@instance
  end
  
  def debug(handle, msg)
    @log.debug("#{handle} #{msg}")
  end
  
  def info(handle, msg)
    @log.info("#{handle} #{msg}")
  end
  
  def error(handle, msg)
    @log.error("#{handle} #{msg}")
  end
  
  def warn(handle, msg)
    @log.warn("#{handle} #{msg}")
  end
  
  private_class_method :new
end

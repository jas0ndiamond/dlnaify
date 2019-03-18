class ConfigFactory
  
  attr_accessor :file
  
  def initialize(file)
    @file = file
  end
  
  def build_transcode_config
    
    #return config for transcoding
    #all the validation checks
    
  end
  
  def build_probe_config
    
    #return config just to probe files
    #really only need ffprobe location
    
    #might be worth using this to determine if we can process the target 
    
  end
  
  def build_info_config
    #encoders/decoders
    #optional file target
    #
    #
  end
end
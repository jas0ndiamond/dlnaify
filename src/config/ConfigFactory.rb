class ConfigFactory
  
  attr_accessor :file, :probe_config, :transcode_config
  
  def initialize(file)
    @file = file
  end
  
  def build_transcode_config
    
    #return config for transcoding
    #all the validation checks
    
    return @transcode_config if  @transcode_config
    @transcode_config = TranscodeConfig.new(@file)
    return @transcode_config
  end
  
  def build_probe_config
    
    #return config just to probe files
    #really only need ffprobe location
    
    #might be worth using this to determine if we can process the target 
    return @probe_config if  @probe_config
    @probe_config = ProbeConfig.new(@file)
    return @probe_config
  end
  
  def build_info_config
    #encoders/decoders
    #filters
    #optional file target
    #
    #
  end
end
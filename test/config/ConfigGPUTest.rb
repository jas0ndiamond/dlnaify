require 'open3'
require 'test/unit'
require_relative "../../src/config/Config.rb"

class ConfigGPUTest < Test::Unit::TestCase 
  
  
  def setup
    
    #assume that basic config tests pass here
    
    
    #load config
    test_dir = File.expand_path(File.dirname(__FILE__))
    conf_dir = File.expand_path("#{test_dir}/../resources/configs")
    @config = Config.new("#{conf_dir}/dlnaify.gpu.conf")

    #check gpu encode enabled
    omit("This requires a dlnaify config with gpu encoding enabled") unless
          @config.get_gpu_transcode_enabled
      
    #check ffmpeg output header for --enable-cuda --enable-cuvid --enable-libnpp --enable-nvenc
    #just check that the flags exist and the syscall for the version info returns correctly. up to the user to troubleshoot the rest
          
    transcoder_output, transcoder_error, transcoder_exit_code = Open3.capture3("#{@config.get_transcoder_binary_location} -v")
          
    omit("This requires a transcoder install with compiled gpu support. Could not find these options in the version output") unless
    (
          transcoder_output =~ /--enable-cuda/ or
          transcoder_output =~ /--enable-cuvid/ or
          transcoder_output =~ /--enable-libnpp/ or
          transcoder_output =~ /--enable-nvenc/
    )
    
    omit("This requires a transcoder install setup correctly with compiled gpu support.") unless 
        transcoder_exit_code == 0
    
     
          
    #check nvidia codecs from config
    omit("This requires an ffmpeg with gpu support") unless
    false 
      #@config.is_valid_target_video_format()
    
    #skip if not there
    
    
    
  end

  def test_default_file

  end
  

  def teardown
    #puts "teardown"
  end
end
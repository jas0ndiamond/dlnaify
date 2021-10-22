require 'test/unit'
require_relative "../../src/config/ProbeConfig.rb"

class ConfigTest < Test::Unit::TestCase 
  
  def setup    
    #get the test dir, which this file should be in
    test_dir = File.expand_path(File.dirname(__FILE__))
    
    #setup tmpdir in resources
    @conf_dir = File.expand_path("#{test_dir}/../resources/configs")
    
    #don't build the config object here, tests may build configs from many different test files
  end

  ################
  #Construction
  
  def test_default_file
    myconfig = nil
    assert_nothing_thrown do
      myconfig = ProbeConfig.new()
    end
    
    assert_not_nil(myconfig)
    assert_true(myconfig.get_cpu_transcode_enabled)
  end
  
  def test_nil_file
    assert_nothing_thrown do
      ProbeConfig.new(nil)
    end
  end
  
  def test_specified_dir
    assert_nothing_thrown do
      ProbeConfig.new("#{@conf_dir}/dlnaify.good.conf")
    end
  end
  
  def test_missing_file
    assert_raise ConfigError do
      ProbeConfig.new("/probably/not/here/at/least/it/better/not/be")
    end
  end
  
  ################
  #Operation
  
  def test_likely_good_config_file
    file = "#{@conf_dir}/dlnaify.good.conf"

    c = ProbeConfig.new(file)
    
    assert_true(c.get_cpu_transcode_enabled)
    
    assert_equal(file, c.get_conf_file)
    
  end
  
  def test_get_encoders
    c = ProbeConfig.new("#{@conf_dir}/dlnaify.good.conf")
    
    assert_true(c.get_supported_encoders.size > 0)
    
    #not guaranteed but likely
    
    #video
    assert_not_nil(c.get_supported_encoders["video"]["gif"])
    assert_equal( "V.....", c.get_supported_encoders["video"]["gif"])
      
    assert_not_nil(c.get_supported_video_encoders["gif"])
    assert_equal("V.....", c.get_supported_video_encoders["gif"])

    #audio
    assert_not_nil(c.get_supported_encoders["audio"]["wavpack"])
    assert_equal("A.....", c.get_supported_encoders["audio"]["wavpack"])
      
    assert_not_nil(c.get_supported_audio_encoders["wavpack"])
    assert_equal("A.....", c.get_supported_audio_encoders["wavpack"])
          
  end
  
  def test_get_decoders
    c = ProbeConfig.new("#{@conf_dir}/dlnaify.good.conf")
    
    assert_true(c.get_supported_decoders.size > 0)
    
    #not guaranteed but likely
    
    #video
    assert_not_nil(c.get_supported_decoders["video"]["gif"])
    assert_equal("V....D", c.get_supported_decoders["video"]["gif"])
      
    assert_not_nil(c.get_supported_video_decoders["gif"])
    assert_equal("V....D", c.get_supported_video_decoders["gif"])

    #audio
    assert_not_nil(c.get_supported_decoders["audio"]["wavpack"])
    assert_equal("AF...D", c.get_supported_decoders["audio"]["wavpack"])
      
    assert_not_nil(c.get_supported_audio_decoders["wavpack"])
    assert_equal("AF...D", c.get_supported_audio_decoders["wavpack"])
    
  end
  
  def test_get_thing
    c = ProbeConfig.new("#{@conf_dir}/dlnaify.good.conf")
    file = "#{@conf_dir}/../SampleVideo_640x360_10mb.mkv"
    
    
    
  end
  
#  def test_use_gpu_transcode
#    assert_nothing_thrown do
#      c = Config.new("#{@conf_dir}/dlnaify.good.conf")
#    
#      c.use_gpu_for_transcode(true)
#      
#      
#      assert_equal(true, c.get_use_gpu_for_transcode)
#      
#    end
#  end
  
  def teardown
    #puts "teardown"
  end
end
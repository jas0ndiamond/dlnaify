require 'test/unit'
require_relative "../../src/config/Config.rb"

class ConfigTest < Test::Unit::TestCase 
  
  attr_accessor :instance
  
  def setup
    #puts "running setup ConfigTest"
    
    #get the test dir, which this file should be in
    test_dir = File.expand_path(File.dirname(__FILE__))
    
    #setup tmpdir in resources
    @conf_dir = File.expand_path("#{test_dir}/../resources/configs")
    
  end

  def test_default_file
    
    myconfig = nil
    assert_nothing_thrown do
      myconfig = Config.new()
    end
    
    assert_not_nil(myconfig)
    assert_true(myconfig.get_cpu_transcode_enabled)
  end
  
  def test_nil_file
    assert_raise ConfigError do
      Config.new(nil)
    end
  end
  
  def test_specified_dir
    assert_nothing_thrown do
      Config.new("#{@conf_dir}/dlnaify.good.conf")
    end
  end
  
  def test_missing_file
    assert_raise ConfigError do
      Config.new("/probably/not/here/at/least/it/better/not/be")
    end
  end
  
  def test_change_video_target_format
    
    assert_nothing_thrown do
      c = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
      format = "hevc"
      
      c.set_target_video_format(format)
      
      assert_equal(format, c.get_target_video_format)
      
      format = "h264"
      c.set_target_video_format(format)
      
      assert_equal(format, c.get_target_video_format)
      
      #check lib too
    end
    
    #unknown format
    assert_raise FormatError do
      c = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
      c.set_target_video_format("hevderpyderp")
    end
    
    #empty format
    assert_raise FormatError do
      c = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
      c.set_target_video_format("")
    end
    
    #known format, unknown transcode library
    assert_raise FormatError do
      c = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
      #Alias/Wavefront PIX image - not likely to be used in dlna operation
      c.set_target_video_format("alias_pix")
    end
  end
  
  def test_change_audio_target_format
    
    assert_nothing_thrown do
      c = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
      format = "ac3"
      c.set_target_audio_format(format)
      
      assert_equal(format, c.get_target_audio_format)
      
      format = "aac"
      c.set_target_audio_format(format)
      
      assert_equal(format, c.get_target_audio_format)
      
      #check lib too
    end
    
    #unknown format
    assert_raise FormatError do
      c = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
      c.set_target_audio_format("hevderpyderp")
    end
    
    #empty format
    assert_raise FormatError do
      c = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
      c.set_target_audio_format("")
    end
    
    #known format, unknown transcode lib
    assert_raise FormatError do
      c = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
      #PCM unsigned 8-bit - not likely to be used in dlna operation
      c.set_target_audio_format("pcm_u8")
    end
    
  end
  
  def test_change_pixel_target_format
    assert_nothing_thrown do
      c = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
      format = "yuv420p"
      
      c.set_target_pixel_format(format)
      
      assert_equal(format, c.get_target_pixel_format)
      
      format = "yuvj420p"
      c.set_target_pixel_format(format)
      
      assert_equal(format, c.get_target_pixel_format)
    end
    
    #unknown format
    assert_raise FormatError do
      c = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
      c.set_target_pixel_format("hevderpyderp")
    end
    
  end
  
  def test_change_target_lang
    
    assert_nothing_thrown do
      c = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
      #Southern Altai - not on blacklist probably
      lang = "alt"
      
      c.set_target_lang(lang)
      
      assert_equal(lang, c.get_target_lang)
      
      lang = "eng"
      c.set_target_lang(lang)
      
      assert_equal(lang, c.get_target_lang)
    end
    
    #blacklisted lang
    assert_raise LangError do
      c = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
      c.set_target_lang("jpn")
    end
    
  end
  
  def teardown
    #puts "teardown"
  end
end
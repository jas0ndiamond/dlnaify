require 'test/unit'
require_relative "../src/Config.rb"

class ConfigGPUTest < Test::Unit::TestCase 
  
  attr_accessor :instance
  
  def setup
    puts "This requires an instance of FFmpeg with gpu support"
    
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
    assert_raise Errno::ENOENT do
      Config.new(nil)
    end
  end
  
  def test_specified_dir
    assert_nothing_thrown do
      Config.new("../conf/dlnaify.conf")
    end
  end
  
  def test_missing_file
    assert_raise Errno::ENOENT do
      Config.new("/probably/not/here/at/least/it/better/not/be")
    end
  end
  
  def teardown
    #puts "teardown"
  end
end
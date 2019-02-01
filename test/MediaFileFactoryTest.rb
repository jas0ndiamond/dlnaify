require 'test/unit'

require_relative "../src/MediaFileFactory.rb"

class MediaFileFactoryTest < Test::Unit::TestCase 
  
  attr_accessor :config 
  
  def setup 
    @blacklisted_audio_test_file = "resources/SampleVideo_640x360_10mb_2_audio_streams_pol_spa.mkv"

    @mostly_blacklisted_audio_test_file1 = "resources/SampleVideo_640x360_10mb_non_blacklisted_audio.mkv"
    @mostly_blacklisted_audio_test_file2 = "resources/SampleVideo_640x360_10mb_non_blacklisted_audio_with_unknown.mkv"
    
    @multiple_whitelisted_langs_test_file = "resources/SampleVideo_640x360_10mb_multi_whitelisted.mkv"
    @multiple_unknown_langs_test_file = "resources/SampleVideo_640x360_10mb_multi_unknown.mkv"
    
    #setup tmpdir in resources
    @tmp_dir = File.expand_path("./resources/tmp")
    Dir.mkdir(@tmp_dir)
    raise RuntimeError.new("Couldn't create tmp dir #{@tmp_dir} for testing") unless 
      File.exists?(@tmp_dir)
      
    conf_file = "../conf/dlnaify.conf"
    raise RuntimeError.new("Couldn't find config file at #{conf_file}") unless 
      File.exists?(conf_file)
      
    @config = Config.new(conf_file)
    
    @valid_file = "./resources/SampleVideo_640x360_10mb.mkv"
    raise RuntimeError.new("Couldn't find valid file at #{@valid_file}") unless 
      File.exists?(@valid_file)
    
    @valid_file_frame_count = 2172
    @valid_file_video_format = "h264"
    @valid_file_audio_format = "aac"
    @valid_file_pixel_format = "yuv420p"
  end
  
  def test_transcoder_probe_query
    factory = MediaFileFactory.new(@config)
    
    media_file = factory.build_media_file(@valid_file, @tmp_dir)
    
    assert_equal(2, media_file.transcoder_probe_info["streams"].length )
    assert_equal(@valid_file_video_format, media_file.transcoder_probe_info["streams"][0]["codec_name"] )
    assert_equal(@valid_file_audio_format, media_file.transcoder_probe_info["streams"][1]["codec_name"] )
    assert_equal(@valid_file_pixel_format, media_file.transcoder_probe_info["streams"][0]["pix_fmt"] )
    

  end
  
  def test_valid_frame_count
    
    factory = MediaFileFactory.new(@config)
    
    media_file = factory.build_media_file(@valid_file, @tmp_dir)
    
    assert_equal(@valid_file_frame_count, media_file.get_total_frame_count)
    
  end
  
  def test_valid_video_format
    
    factory = MediaFileFactory.new(@config)
    
    media_file = factory.build_media_file(@valid_file, @tmp_dir)
    
    assert_equal(@valid_file_video_format, media_file.get_video_format)
    assert_equal(@valid_file_pixel_format, media_file.get_video_stream.pixel_format)
    
  end
  
  def test_valid_audio_format
    factory = MediaFileFactory.new(@config)
    
    media_file = factory.build_media_file(@valid_file, @tmp_dir)
    
    assert_equal(@valid_file_audio_format, media_file.get_audio_format)
  end
  
  def test_blacklisted_langs   
    #1 vid stream, 2 audio streams, target lang not among them
    
    factory = MediaFileFactory.new(@config)
    
    assert_raise LangError do
      media_file = factory.build_media_file(@blacklisted_audio_test_file, "./")
    end
  
  end
  
  def test_blacklisted_langs_with_one_workable_lang
    
    #1 vid stream, 4 audio streams, target lang not among them, 3 streams with blacklisted langs
    
    factory = MediaFileFactory.new(@config)
    
    #has "ang" stream (ancient english)
    assert_nothing_thrown do
      media_file = factory.build_media_file(@mostly_blacklisted_audio_test_file1, "./")
    end
    
    #one stream with no language tag. assume that's what we want
    assert_nothing_thrown do
      media_file = factory.build_media_file(@mostly_blacklisted_audio_test_file2, "./")
    end
    
  end
  
  def test_blacklisted_multiple_whitelisted_lang
    #1 vid stream, 4 audio streams, target langs not among them
    
    factory = MediaFileFactory.new(@config)
    
    #grab the first one
    assert_nothing_thrown do
      media_file = factory.build_media_file(@multiple_whitelisted_langs_test_file, "./")
    end
  end
  
  def test_multiple_unknown_langs
    #1 vid stream, 4 audio streams, multiple unknown langs, 

    factory = MediaFileFactory.new(@config)
    
    #grab the first one
    assert_nothing_thrown do
      media_file = factory.build_media_file(@multiple_unknown_langs_test_file, "./")
    end
  end
  
  def test_valid_subtitle_format
    
  end
  
  def teardown
    #puts "teardown"
    #puts "Deleting tmpdir #{@tmp_dir}"

    Dir.rmdir(@tmp_dir)
    raise RuntimeError.new("Could not remove tmp dir #{@tmp_dir}") unless
       !File.exists?(@tmp_dir)
  end
end
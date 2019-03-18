require 'test/unit'

require_relative "../../src/config/Config.rb"
require_relative "../../src/media/MediaFileFactory.rb"
require_relative "../../src/convert/ConvertJobFactory.rb"

require_relative "../FFmpegTestUtils.rb"

#ConvertJobFactory assembles the underlying ffmpeg call.
#make sure it doesn't suck
class ConvertJobFactoryTest < Test::Unit::TestCase 
  
  attr_accessor :media_file_factory
  attr_accessor :convert_job_factory
  attr_accessor :simple_test_file
  attr_accessor :config
  
  def setup  
    
    #get the test dir, which this file should be in
    test_dir = File.expand_path(File.dirname(__FILE__))
    
    #setup tmpdir in resources
    @conf_dir = File.expand_path("#{test_dir}/../resources/configs")
    
    #create a config
    #need config to confirm test values
    @config = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
    #paths to files
    @simple_test_file = "#{test_dir}/../resources/SampleVideo_640x360_10mb.mkv"
    
    #two audio streams, eng and spa, in order
    @two_audio_streams_test_file = "#{test_dir}/../resources/SampleVideo_640x360_10mb_2_audio_streams.mkv"
    
    #two audio streams, spa and eng, in order    
    @two_audio_streams_spa_first_test_file = "#{test_dir}/../resources/SampleVideo_640x360_10mb_2_audio_streams_spa_first.mkv"
    
    #blacklisted audio, no eng streams available
    @blacklisted_audio_test_file = "#{test_dir}/../resources/SampleVideo_640x360_10mb_2_audio_streams_pol_spa.mkv"
    
    #unknown audio
    @unknown_audio_test_file = "#{test_dir}/../resources/SampleVideo_640x360_10mb_unknown_audio.mkv"
    
    #many langs, only 1 not on blacklist, no whitelisted langs
    @non_blacklisted_audio_test_file = "#{test_dir}/../resources/SampleVideo_640x360_10mb_non_blacklisted_audio.mkv"
    
    @ffmpeg_test_utils = FFmpegTestUtils.new(@config.get_transcoder_binary_location, @config.get_transcoder_probe_binary_location)  
    
    #create a MediaFileFactory from our config
    @media_file_factory = MediaFileFactory.new(config)
    
    #create a ConvertJobFactory from our config
    @convert_job_factory = ConvertJobFactory.new(config)
    
    #supply proper mediafiles in the tests
  end
  
  def test_simple
    #basic test. 1 vid stream, 1 audio stream
    #dest doesn't really matter as long as it's accessible.
    #we're not executing the transcode
    media_file = @media_file_factory.build_media_file(@simple_test_file, "./")
    
    job = @convert_job_factory.build_convert_job(media_file)
    
    #/home/jason/FFmpeg/ffmpeg -y -i '/home/jason/dlnaify/test/resources/SampleVideo_640x360_10mb.mkv'  -c:v copy  -c:a copy  -map 0:0 -map 0:1 '/home/jason/dlnaify/test/SampleVideo_640x360_10mb.mkv'
    assert_equal(
      @config.get_transcoder_binary_location << 
        " -v info -hide_banner" <<
        " -y -i" <<
        " '" << media_file.path << "' "<<
        "-c:v copy -c:a copy -map 0:0 -map 0:1 " <<
        "'" << media_file.get_safe_dest_path << "'" <<
        " 2>&1",
      job.syscall
    )
  end
  
  def test_correct_lang_audio_chosen
    #1 vid stream, 2 audio streams. english is first
    #dest doesn't really matter as long as it's accessible.
    #we're not executing the transcode
    media_file = @media_file_factory.build_media_file(@two_audio_streams_test_file, "./")
    
    job = @convert_job_factory.build_convert_job(media_file)
    
    #puts "English first: #{job.syscall}"
    #/home/jason/FFmpeg/ffmpeg -y -i '/home/jason/dlnaify/test/resources/SampleVideo_640x360_10mb_2_audio_streams.mkv' -c:v copy -c:a copy -map 0:0 -map 0:1 '/home/jason/dlnaify/test/SampleVideo_640x360_10mb_2_audio_streams.mkv'
    assert_equal(
      @config.get_transcoder_binary_location << 
        " -v info -hide_banner" <<
        " -y -i" <<
        " '" << media_file.path << "' "<<
        "-c:v copy -c:a copy -map 0:0 -map 0:1 " <<
        "'" << media_file.get_safe_dest_path << "'" <<
        " 2>&1",
      job.syscall
    )
  end
  
  def test_correct_lang_audio_chosen_harder
    #1 vid stream, 2 audio streams, english is not first
    #dest doesn't really matter as long as it's accessible.
    #we're not executing the transcode
    media_file = @media_file_factory.build_media_file(@two_audio_streams_spa_first_test_file, "./")
    
    job = @convert_job_factory.build_convert_job(media_file)
    
    #puts "English 2nd: #{job.syscall}"
    #/home/jason/FFmpeg/ffmpeg -y -i '/home/jason/dlnaify/test/resources/SampleVideo_640x360_10mb_2_audio_streams_spa_first.mkv' -c:v copy -c:a copy -map 0:0 -map 0:2 '/home/jason/dlnaify/test/SampleVideo_640x360_10mb_2_audio_streams_spa_first.mkv'
    assert_equal(
      @config.get_transcoder_binary_location << 
        " -v info -hide_banner" <<
        " -y -i" <<
        " '" << media_file.path << "' "<<
        "-c:v copy -c:a copy -map 0:0 -map 0:2 " <<
        "'" << media_file.get_safe_dest_path << "'" <<
        " 2>&1",
      job.syscall
    )
  end
  
  def test_transcode_video
    #test an actual transcode - where we convert to a new format
    
    #will need to set target in our own config object
    myconfig = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
    #test file should be h264 so let's convert to hevc
    #encoder will be libx265
    myconfig.set_target_video_format("hevc")
    
    my_media_file_factory = MediaFileFactory.new(myconfig)
    
    media_file = my_media_file_factory.build_media_file(@simple_test_file, "./")
    
    assert_equal("hevc", myconfig.get_target_video_format)
    assert_equal("libx265", myconfig.get_target_video_encoder)
    
    #check first, to make sure the test file is in the expected format
    assert_equal(@ffmpeg_test_utils.get_video_format(@simple_test_file), media_file.get_video_stream.format)
    
    my_convert_job_factory = ConvertJobFactory.new(myconfig)
    job = my_convert_job_factory.build_convert_job(media_file)
    
    #ffmpeg -y -i '/home/jason/dlnaify/test/resources/SampleVideo_640x360_10mb.mkv'  -c:v copy  -c:a copy  -map 0:0 -map 0:1 '/home/jason/dlnaify/test/SampleVideo_640x360_10mb.mkv'
    assert_equal(
      @config.get_transcoder_binary_location << 
        " -v info -hide_banner" <<
        " -y -i" <<
        " '" << media_file.path << "' "<<
        "-c:v #{myconfig.get_target_video_encoder} -c:a copy -map 0:0 -map 0:1 " <<
        "'" << media_file.get_safe_dest_path << "'" <<
        " 2>&1",
      job.syscall
    )
  end
  
  def test_transcode_video_experimental
    #test an actual transcode - where we convert to a new format
    
    #will need to set target in our own config object
    myconfig = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
    #avui is experimental
    myconfig.set_target_video_format("avui")
    
    #skip if not experimental
    
    my_media_file_factory = MediaFileFactory.new(myconfig)
    
    media_file = my_media_file_factory.build_media_file(@simple_test_file, "./")
    
    #check first, to make sure the test file is in the expected format
    assert_equal(@ffmpeg_test_utils.get_video_format(@simple_test_file), media_file.get_video_stream.format)
    
    my_convert_job_factory = ConvertJobFactory.new(myconfig)
    job = my_convert_job_factory.build_convert_job(media_file)
    
    #ffmpeg -y -i '/home/jason/dlnaify/test/resources/SampleVideo_640x360_10mb.mkv'  -c:v copy  -c:a copy  -map 0:0 -map 0:1 '/home/jason/dlnaify/test/SampleVideo_640x360_10mb.mkv'
    assert_equal(
      @config.get_transcoder_binary_location << 
        " -v info -hide_banner" <<
        " -y -i" <<
        " '" << media_file.path << "' "<<
        "-strict -2 " << #avui
        "-c:v #{myconfig.get_target_video_encoder} -c:a copy -map 0:0 -map 0:1 " <<
        "'" << media_file.get_safe_dest_path << "'" <<
        " 2>&1",
      job.syscall
    )
  end

  def test_transcode_video_and_pixel_format
    #test an actual transcode - where we convert to a new format
    
    #will need to set target in our own config object
    myconfig = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
    #test file should be h264 so let's convert to hevc
    #encoder will be libx265
    myconfig.set_target_video_format("hevc")
    myconfig.set_target_pixel_format("gray")
    
    my_media_file_factory = MediaFileFactory.new(myconfig)
    
    media_file = my_media_file_factory.build_media_file(@simple_test_file, "./")
    
    assert_equal("hevc", myconfig.get_target_video_format)
    assert_equal("libx265", myconfig.get_target_video_encoder)
    
    #check first, to make sure the test file is in the expected format
    assert_equal(@ffmpeg_test_utils.get_video_format(@simple_test_file), media_file.get_video_stream.format)
    
    my_convert_job_factory = ConvertJobFactory.new(myconfig)
    job = my_convert_job_factory.build_convert_job(media_file)
    
    #ffmpeg -y -i '/home/jason/dlnaify/test/resources/SampleVideo_640x360_10mb.mkv'  -c:v copy  -c:a copy  -map 0:0 -map 0:1 '/home/jason/dlnaify/test/SampleVideo_640x360_10mb.mkv'
    assert_equal(
      @config.get_transcoder_binary_location << 
        " -v info -hide_banner" <<
        " -y -i" <<
        " '" << media_file.path << "' "<<
        "-c:v #{myconfig.get_target_video_encoder} " <<
        "-pix_fmt gray " <<
        "-c:a copy -map 0:0 -map 0:1 " <<
        "'" << media_file.get_safe_dest_path << "'" <<
        " 2>&1",
      job.syscall
    )
  end
  
  def test_copy_video_and_change_pixel_format
    #test an actual transcode - where we convert to a new format
    
    #changing pixel format implies transcode. transcode to its current format
    
    #will need to set target in our own config object
    myconfig = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
    myconfig.set_target_pixel_format("gray")
    
    my_media_file_factory = MediaFileFactory.new(myconfig)
    
    media_file = my_media_file_factory.build_media_file(@simple_test_file, "./")
    
    #check first, to make sure the test file is in the expected format
    assert_equal(@ffmpeg_test_utils.get_video_format(@simple_test_file), media_file.get_video_stream.format)
    
    my_convert_job_factory = ConvertJobFactory.new(myconfig)
    job = my_convert_job_factory.build_convert_job(media_file)
    
    #ffmpeg -y -i '/home/jason/dlnaify/test/resources/SampleVideo_640x360_10mb.mkv'  -c:v copy  -c:a copy  -map 0:0 -map 0:1 '/home/jason/dlnaify/test/SampleVideo_640x360_10mb.mkv'
    assert_equal(
      @config.get_transcoder_binary_location << 
        " -v info -hide_banner" <<
        " -y -i" <<
        " '" << media_file.path << "' "<<
        "-c:v libx264 " <<
        "-pix_fmt gray " <<
        "-c:a copy -map 0:0 -map 0:1 " <<
        "'" << media_file.get_safe_dest_path << "'" <<
        " 2>&1",
      job.syscall
    )
  end
    
  def test_transcode_audio
    #test an actual transcode - where we convert to a new format
    
    #will need to set target in our own config object
    myconfig = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
    #test file should be aac so let's convert to ac3
    #encoder will be ac3
    myconfig.set_target_audio_format("ac3")
    
    my_media_file_factory = MediaFileFactory.new(myconfig)
    
    media_file = my_media_file_factory.build_media_file(@simple_test_file, "./")
    
    assert_equal("ac3", myconfig.get_target_audio_format)
    assert_equal("ac3", myconfig.get_target_audio_encoder)
    
    #check first, to make sure the test file is in the expected format
    assert_equal(@ffmpeg_test_utils.get_video_format(@simple_test_file), media_file.get_video_stream.format)
    
    my_convert_job_factory = ConvertJobFactory.new(myconfig)
    job = my_convert_job_factory.build_convert_job(media_file)
    
    #ffmpeg -y -i '/home/jason/dlnaify/test/resources/SampleVideo_640x360_10mb.mkv'  -c:v copy  -c:a copy  -map 0:0 -map 0:1 '/home/jason/dlnaify/test/SampleVideo_640x360_10mb.mkv'
    assert_equal(
      @config.get_transcoder_binary_location << 
        " -v info -hide_banner" <<
        " -y -i" <<
        " '" << media_file.path << "' "<<
        "-c:v copy "<<
        "-c:a #{myconfig.get_target_audio_encoder} -map 0:0 -map 0:1 " <<
        "'" << media_file.get_safe_dest_path << "'" <<
        " 2>&1",
      job.syscall
    )
  end
  
  def test_transcode_audio_experimental
    #use libvorbis
    #test an actual transcode - where we convert to a new format
    
    #will need to set target in our own config object
    myconfig = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
    #test file should be h264 so let's convert to vorbis
    #encoder will be libvorbis
    myconfig.set_target_audio_format("vorbis")
    
    my_media_file_factory = MediaFileFactory.new(myconfig)
    
    media_file = my_media_file_factory.build_media_file(@simple_test_file, "./")
    
    assert_equal("vorbis", myconfig.get_target_audio_format)
    assert_equal("libvorbis", myconfig.get_target_audio_encoder)
    
    #check first, to make sure the test file is in the expected format
    assert_equal(@ffmpeg_test_utils.get_video_format(@simple_test_file), media_file.get_video_stream.format)
    
    my_convert_job_factory = ConvertJobFactory.new(myconfig)
    job = my_convert_job_factory.build_convert_job(media_file)
    
    #ffmpeg -y -i '/home/jason/dlnaify/test/resources/SampleVideo_640x360_10mb.mkv'  -c:v copy  -c:a copy  -map 0:0 -map 0:1 '/home/jason/dlnaify/test/SampleVideo_640x360_10mb.mkv'
    assert_equal(
      @config.get_transcoder_binary_location << 
        " -v info -hide_banner" <<
        " -y -i" <<
        " '" << media_file.path << "' "<<
        "-c:v copy "<<
        "-strict -2 " << #libvorbis
        "-c:a #{myconfig.get_target_audio_encoder} -map 0:0 -map 0:1 " <<
        "'" << media_file.get_safe_dest_path << "'" <<
        " 2>&1",
      job.syscall
    )
  end
  
  def test_transcode_audio_and_correct_lang_chosen
    
    #will need to set target in our own config object
    myconfig = Config.new("#{@conf_dir}/dlnaify.good.conf")
    
    #test file should be h264 so let's convert to vorbis
    #encoder will be libvorbis
    myconfig.set_target_audio_format("vorbis")
    
    my_media_file_factory = MediaFileFactory.new(myconfig)
    
    assert_equal("vorbis", myconfig.get_target_audio_format)
    assert_equal("libvorbis", myconfig.get_target_audio_encoder)
    
    #1 vid stream, 2 audio streams, english is not first
    #dest doesn't really matter as long as it's accessible.
    #we're not executing the transcode
    media_file = my_media_file_factory.build_media_file(@two_audio_streams_spa_first_test_file, "./")
    
    my_convert_job_factory = ConvertJobFactory.new(myconfig)
    job = my_convert_job_factory.build_convert_job(media_file)
    
    #puts "English 2nd: #{job.syscall}"
    #/home/jason/FFmpeg/ffmpeg -y -i '/home/jason/dlnaify/test/resources/SampleVideo_640x360_10mb_2_audio_streams_spa_first.mkv' -c:v copy -c:a copy -map 0:0 -map 0:2 '/home/jason/dlnaify/test/SampleVideo_640x360_10mb_2_audio_streams_spa_first.mkv'
    assert_equal(
      @config.get_transcoder_binary_location << 
        " -v info -hide_banner" <<
        " -y -i" <<
        " '" << media_file.path << "' "<<
        "-c:v copy " << 
        "-strict -2 " << #libvorbis
        "-c:a #{myconfig.get_target_audio_encoder} -map 0:0 -map 0:2 " <<
        "'" << media_file.get_safe_dest_path << "'" <<
        " 2>&1",
      job.syscall
    )
  end
    
  def test_unknown_audio_lang
    #not all audio streams have lang tags
    
    #only 1 stream available
    media_file = @media_file_factory.build_media_file(@simple_test_file, "./")
    
    job = @convert_job_factory.build_convert_job(media_file)
    
    assert_equal(
      @config.get_transcoder_binary_location << 
        " -v info -hide_banner" <<
        " -y -i" <<
        " '" << media_file.path << "' "<<
        "-c:v copy -c:a copy -map 0:0 -map 0:1 " <<
        "'" << media_file.get_safe_dest_path << "'" <<
        " 2>&1",
      job.syscall
    )  
  end
  
  def teardown
    
  end
end
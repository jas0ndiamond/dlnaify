class FFmpegTestUtils
  
  attr_accessor :ffmpeg_bin
  attr_accessor :ffprobe_bin
  
  def initialize(ffmpeg_bin="/usr/bin/ffmpeg", ffprobe_bin="/usr/bin/ffprobe")
    #bin parameters will likely come from Config objects.
    #the default values are just reasonable guesses
    
    #check file locations. exception if bad
    raise "Invalid ffmpeg/ffprobe binary locations" unless 
      (File.exists?(ffmpeg_bin) and File.exists?(ffprobe_bin))
    
    @ffmpeg_bin = ffmpeg_bin
    @ffprobe_bin = ffprobe_bin
    
  end
  
  def get_video_format(file, stream=0)
    #ffmpeg call to get stream name at steam index

    #ffprobe -v error -select_streams v:0 -show_entries stream=codec_name  -of default=noprint_wrappers=1:nokey=1 resources/SampleVideo_640x360_10mb.mkv

    syscall = "#{@ffprobe_bin} -v error -select_streams v:#{stream}" <<
      " -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 " <<
      "#{file}"
    
    output = ""
      
    #run and check ret val, and throw exception if bad
    Open3.popen3(syscall) {|stdin, stdout, stderr, wait_thr|
    
      raise "Could determine video format of #{file}:#{stream} with ffprobe." unless
        wait_thr.value == 0
        
      output = stdout.read
    }
      
    return output.chomp
  end
  
  def get_audio_format(file, stream=0)
    #ffmpeg call to get stream name at stream index
    
    syscall = "#{@ffprobe_bin} -v error -select_streams a:#{stream}" <<
      " -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 " <<
      "#{file}"
    
    output = ""
      
    #run and check ret val, and throw exception if bad
    Open3.popen3(syscall) {|stdin, stdout, stderr, wait_thr|
    
      raise "Could determine audio format of #{file}:#{stream} with ffprobe." unless
        wait_thr.value == 0
        
      output = stdout.read
    }
    
    return output.chomp
  end
  
  def get_audio_lang(file, stream=0)
    #ffmpeg call to get stream name at stream index
    #https://stackoverflow.com/questions/40647168/use-ffprobe-to-view-audio-tracks-by-language
    
    syscall = "#{@ffprobe_bin} -v error -select_streams a:#{stream}" <<
      " -show_entries stream_tags=language -of default=noprint_wrappers=1:nokey=1 " <<
      "#{file}"
    
    output = ""
      
    #run and check ret val, and throw exception if bad
    Open3.popen3(syscall) {|stdin, stdout, stderr, wait_thr|
    
      raise "Could determine audio lang of #{file}:#{stream} with ffprobe." unless
        wait_thr.value == 0
        
      output = stdout.read
    }
    
    return output.chomp
  end
  
  #def get volume info stuff
  
end
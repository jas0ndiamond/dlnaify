require_relative '../config/Config.rb'
require_relative '../convert/ConvertJob.rb'
require_relative '../log/MyLogger.rb'

#assemble system call from media file and config
class ConvertJobFactory
  
  attr_accessor :config
  
  def initialize(config)
    @config = config
    
    #if cpu-transcode, probe cpu count
    
  end
  
  def build_convert_job(media_file)
    MyLogger.instance.info("ConvertJobFactory", "Building ConvertJob for #{media_file.path}")

    
    job = ConvertJob.new(media_file)
    
    raise "Cannot build convert job from null MediaFile" unless media_file
    
    #set process check sleep interval
    
    #assemble syscall
    
    #determine gpu or cpu transcode
    #both -> gpu
    
    #any env prefixes
    #cuda ld_libary_path
    #taskset cpu affinity
    
    #ffmpeg binary
    #syscall = "" << @config.get_transcoder_binary_location
    syscall = Array.new
    syscall.push(@config.get_transcoder_binary_location)
     
    #input file
    #always overwrite
    #syscall << " -y -i '#{media_file.path}' "
    syscall.push("-v")
    syscall.push("info")
    syscall.push("-hide_banner")
    syscall.push("-y")
    syscall.push("-i")
    
    #media_file.path is not safe 
    syscall.push("'#{media_file.path}'")
    
    target_video_format = @config.get_target_video_format
    target_audio_format = @config.get_target_audio_format
    
    target_video_encoder = @config.get_target_video_encoder
    target_audio_encoder = @config.get_target_audio_encoder
    
    raise "Invalid video format" unless target_video_format
    raise "Invalid audio format" unless target_audio_format
    
    #output video format
    #use 'copy' if no format change
    #add experimental flags if necessary
    video_encoder_info = @config.get_video_encoder_info(target_video_encoder)
    
    MyLogger.instance.info("ConvertJobFactory", "video target: #{target_video_format} vs current: #{media_file.get_video_stream.format}")
    MyLogger.instance.info("ConvertJobFactory", "video target: #{target_video_format} has encoder info: #{video_encoder_info}")

    if
    (
      target_video_format == media_file.get_video_stream.format and
      @config.get_target_pixel_format == media_file.get_video_stream.pixel_format 
    )
      #only copy if we're already in the target pixel fmt
      #if we have a good video format but a bad pixel format, the result is unplayable
      #-c:v copy may override -pix_fmt param
      MyLogger.instance.info("ConvertJobFactory", "Copying video format")
      #syscall << " -c:v copy "
      syscall.push("-c:v")
      syscall.push("copy")
    elsif(video_encoder_info =~ /^V..X../)
      #experimental
      MyLogger.instance.info("ConvertJobFactory", "Using experimental video encoder for #{target_video_format}")
      #syscall << " -strict -2 -c:v #{true_video_format} "
      syscall.push("-strict")
      syscall.push("-2")
      syscall.push("-c:v")
      syscall.push(target_video_encoder)
    else
      #syscall << " -c:v #{true_video_format} "
      syscall.push("-c:v")
      syscall.push(target_video_encoder)
    end
    
    #pixel format
    #compare video stream pixfmt with target
    if(media_file.get_video_stream.pixel_format != @config.get_target_pixel_format)
      MyLogger.instance.info("ConvertJobFactory", "Changing pixel format to #{@config.get_target_pixel_format}")
      #syscall << " -pix_fmt #{@config.get_target_pixel_format} "
      syscall.push("-pix_fmt")
      syscall.push(@config.get_target_pixel_format)
    else
      MyLogger.instance.info("ConvertJobFactory", "Keeping video stream pixel format")
    end
    
    #output audio format
    #use 'copy' if no format change
    #add experimental flags if necessary
    audio_encoder_info = @config.get_audio_encoder_info(target_audio_format)
    
    MyLogger.instance.info("ConvertJobFactory", "audio target: #{target_audio_format} vs current: #{media_file.get_audio_stream.format}")
    MyLogger.instance.info("ConvertJobFactory", "audio target: #{target_audio_format} has encoder info: #{audio_encoder_info}")

    
    if(target_audio_format == media_file.get_audio_stream.format)
      MyLogger.instance.info("ConvertJobFactory", "Copying audio format")
      #syscall << " -c:a copy "
      syscall.push("-c:a")
      syscall.push("copy")
    elsif(audio_encoder_info =~ /^A..X../)
      #experimental
      MyLogger.instance.info("ConvertJobFactory", "Using experimental audio encoder for #{target_audio_format}")
      #syscall << " -strict -2 -c:a #{target_audio_format} "
      syscall.push("-strict")
      syscall.push("-2")
      syscall.push("-c:a")
      syscall.push(target_audio_encoder)
    else
      #syscall << " -c:a #{target_audio_format} "
      syscall.push("-c:a")
      syscall.push(target_audio_encoder)
    end
    
    #audio stream mapping
    #get stream number from AudioStream object in mediafile
    audio_stream = media_file.get_audio_stream
    #syscall << " -map 0:0 -map 0:#{audio_stream.identifier}"
    syscall.push("-map")
    syscall.push("0:0")
    syscall.push("-map")
    syscall.push("0:#{audio_stream.identifier}")
    
    #volume normalization, if specified
    
    #output file at output dest
    syscall.push("'#{media_file.get_safe_dest_path}'")
    
    #ffmpeg prints on stdout and stderr
    syscall.push("2>&1")
    
    syscall_str = syscall.join(" ")
    MyLogger.instance.info("ConvertJobFactory", "Final syscall for #{media_file.path}: #{syscall_str}")
    job.set_syscall(syscall_str)
    
    return job
  end
  
  
end
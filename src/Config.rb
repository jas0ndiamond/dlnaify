require 'logger'
require 'json'

require_relative "../src/MyLogger.rb"
require_relative "../src/exceptions/LangError.rb"
require_relative "../src/exceptions/FormatError.rb"
require_relative "../src/exceptions/ConfigError.rb"

class Config

  #directives
  GPU_TRANSCODE_ENABLED = "gpu_transcode_enabled"
  CPU_TRANSCODE_ENABLED = "cpu_transcode_enabled"
  GPU_HWACCEL = "gpu_hwaccel"
  
  TARGET_LANG = "target_lang"
  TARGET_LANG_BLACKLIST = "target_lang_blacklist"
  
  TARGET_VIDEO_FORMAT = "target_video_format"

  TARGET_VIDEO_CPU_TRANSCODE_ENCODER = "target_video_cpu_transcode_encoder"
  TARGET_VIDEO_GPU_TRANSCODE_ENCODER = "target_video_gpu_transcode_encoder"
  
  TARGET_AUDIO_FORMAT = "target_audio_format"
  TARGET_AUDIO_TRANSCODE_ENCODER = "target_audio_transcode_encoder"
  
  TARGET_FILE_EXTENSION = "target_file_extension"
  
  TARGET_PIXEL_FORMAT = "target_pixel_format"
  
  TRANSCODER_NAME = "transcoder_name"
  TRANSCODER_BINARY_LOCATION = "transcoder_binary_location"
  TRANSCODER_PROBE_BINARY_LOCATION = "transcoder_probe_binary_location"
  TRANSCODER_GPU_SYSCALL_PREFIX = "transcoder_gpu_syscall_prefix"
  TRANSCODER_CPU_SYSCALL_PREFIX = "transcoder_cpu_syscall_prefix"

  SUPPORTED_ENCODERS = "supported_encoders"
  SUPPORTED_ENCODERS_VIDEO = "video"
  SUPPORTED_ENCODERS_AUDIO = "audio"
  SUPPORTED_ENCODERS_SUBTITLE = "subtitle"
  
  SUPPORTED_DECODERS = "supported_decoders"
  SUPPORTED_DECODERS_VIDEO = "video"
  SUPPORTED_DECODERS_AUDIO = "audio"
  SUPPORTED_DECODERS_SUBTITLE = "subtitle"
  
  SUPPORTED_PIXEL_FORMATS = "supported_pixel_formats"
  
  SUPPORTED_FILE_EXTENSIONS = "supported_file_extensions"
  SUPPORTED_FILE_FORMATS = "supported_file_formats"
  
  TRANSCODE_TARGETS = "transcode_targets"
  
  ###################
  #get rid of these, resolve lib from format name properly
  
  VIDEO_TRANSCODE_ENCODERS_CPU = {
    "h264" => "libx264",
    "hevc" => "libx265",
    "avui" => "avui"
  }
  
  VIDEO_TRANSCODE_ENCODERS_GPU = {
    "h264" => "h264_nvenc",
    "hevc" => "hevc_nvenc"
  }
  
  AUDIO_TRANSCODE_ENCODERS = {
    "aac" => "aac",
    "ac3" => "ac3",
    "vorbis" => "libvorbis"
    
  }
  
  NVIDIA_ENCODERS = [
    "h264_nvenc",
    "nvenc",
    "nvenc_h264",
    "nvenc_hevc",
    "hevc_nvenc" 
  ]
  
  NVIDIA_DECODERS = [
    "h264_cuvid",
    "hevc_cuvid",
    "mjpeg_cuvid",
    "mpeg1_cuvid",
    "mpeg2_cuvid",
    "mpeg4_cuvid",
    "vc1_cuvid",
    "vp8_cuvid",
    "vp9_cuvid"
  ]
  
  NVIDIA_HW_ACCELS = [
    "cuda",
    "cuvid"
  ]
  ####################
  
  #target language (ENG/FRA/SPN/JAP/...)
  #target file suffix
  #/r refresh rate
  #pty params
  #supported source file formats

  #gpu decode
  #LD_LIBRARY_PATH=/usr/local/cuda/lib64 ./ffmpeg -hwaccel cuvid -hwaccel_device 0 1
  #-i ../my_in_file.mkv -c:v h264_nvenc -pix_fmt yuv420p -c:a copy
  #-map 0:0 -map 0:1 my_out_file.mkv

  attr_accessor :config
  def initialize(conf_file = "#{ File.dirname(__FILE__) }/../conf/dlnaify.conf" )

    raise ConfigError.new("Invalid config file") unless conf_file && File.exists?(conf_file)
    
    #read dlnaify.conf in dir
    #set defaults
    #load directives

    

    #sanitize conf file path
    MyLogger.instance.debug("Config", "Loading config from directory #{conf_file}")

    raw_config = load_config(conf_file)
    
    #core directives dlnaify.conf
    
    #ffmpeg binaries
    #check config directives for values
    #no values? try which ffmpeg/ffprobe

    #our output might want multiple types for a device supporting multiple types

    #targetting
    #coupled to device?? --> possible multiple tvs requiring different things
    #cli options for video/audio/format
    #devices/tv.config?
    #how to handle name to libname mapping??
      #x264 => libx264
      #vorbis => lib1.0vorbis_derp

    #sanity check. exception if failure
    config_sanity_check(raw_config)
    
    ####################
    #after this point, we can continue to build the config
    #provided what we already have is coherent
    
    #these require viable binaries for ffmpeg and ffprobe
    
    #initialize here so that gpu/cpu transcode switches can be referenced
    #in load_ methods
    @config = raw_config
    
    #load encoders
    encoders = load_encoders(raw_config)
    
    #load decoders
    decoders = load_decoders(raw_config)
    
    #load formats
    file_formats = load_file_formats(raw_config)
    
    #load pixel formats
    pix_formats = load_pixel_formats(raw_config)
    
    #target devices
    #load_transcode_targets(my_config)

    #####################
    
    #assemble the config for the final validation

    @config[SUPPORTED_ENCODERS] = encoders
    @config[SUPPORTED_DECODERS] = decoders
    @config[SUPPORTED_FILE_FORMATS] = file_formats
    @config[SUPPORTED_PIXEL_FORMATS] = pix_formats
    
#    puts JSON.pretty_generate(@config)
#    puts "================="
#    puts get_cpu_transcode_enabled
    
    #####################
    
    #basic target validation
    #
    #targets are loaded at this point
    #
    #validate each

    set_target_video_format(raw_config[TARGET_VIDEO_FORMAT])
      
    set_target_audio_format(raw_config[TARGET_AUDIO_FORMAT])
    
    #validate file extension? how?
      
    set_target_pixel_format(raw_config[TARGET_PIXEL_FORMAT])

    set_target_lang(raw_config[TARGET_LANG])
    
    #puts "video encoder #{get_target_video_cpu_encoder}"
    #puts "audio encoder #{get_target_audio_encoder}"
    
    #####################
    #final check holla
    # 
    # validate that formats have valid encoders
    # 
    system_sanity_check
    
    #load_transcode_targets
    
    #target check
    #no sanity check, still accept avcodec from cli
    #even if targets are invalid, still proceed 
    
    ################################
    #at this point validation is done
    #load my_config into @config
    #set_target_whatever should work and be testable
    

    
  end
  
  def load_config(conf_file)
    raise ConfigError.new("Need a defined config file") unless conf_file
    
    #just read the config file and load the whitelisted directives
    #can't do validation checks on targets just yet.
    #ffmpeg_bin_location etc may not be validated
    #wait on config_sanity_check first
    
    config_hash = {
          GPU_TRANSCODE_ENABLED => false, #optional
          CPU_TRANSCODE_ENABLED => true,  #required if gpu_transcode_enabled is false
          GPU_HWACCEL => nil,  #optional
          TARGET_VIDEO_FORMAT => "h264", #required
          TARGET_FILE_EXTENSION => "mkv",  #required
          TARGET_PIXEL_FORMAT => "yuv420p",  #optional
          TARGET_AUDIO_FORMAT => "aac",  #required
          TARGET_LANG => "eng",  #required
          TARGET_LANG_BLACKLIST => Hash.new, #optional
          TRANSCODER_NAME => nil,  #required
          TRANSCODER_BINARY_LOCATION => nil, #required
          TRANSCODER_PROBE_BINARY_LOCATION => nil, #required
          TRANSCODER_GPU_SYSCALL_PREFIX => nil, #optional
          TRANSCODER_CPU_SYSCALL_PREFIX => nil, #optional
          SUPPORTED_ENCODERS => nil,
          SUPPORTED_DECODERS => nil,
          SUPPORTED_FILE_FORMATS => nil,
          SUPPORTED_FILE_EXTENSIONS => nil,
          SUPPORTED_PIXEL_FORMATS => nil,
          TRANSCODE_TARGETS => Hash.new
    }
    
    File.open(conf_file, "r") do |f|
      f.each_line do |line|
        #trailing newline
        line.chomp!

        #leading whitespace
        line.gsub!(/\s*/, "")

        if(line !~ /^#/ and line['='])
          #(directive,value) = line.split("=")
          #directive is all chars from ^ to the first =
          #value is all chars from first = to $
          #value may contain '='
          directive = line[0, line.index('=') ]
          value = line[line.index('=')+1, line.length]

          if(directive and directive.length > 0 and value and value.length > 0)
            MyLogger.instance.debug("Config", "Loading directive #{directive} => #{value}" )

            if(config_hash.key?(directive))
              if(directive == SUPPORTED_FILE_EXTENSIONS)
                config_hash[directive] = value.split(',')
                
                raise FormatError.new("Could not parse list of supported file formats") unless
                  config_hash[directive] && config_hash[directive].length > 0

              elsif(directive == CPU_TRANSCODE_ENABLED)
                if(value.to_i == 1)
                  config_hash[directive] = true
                else
                  config_hash[directive] = false
                end
              elsif(directive == GPU_TRANSCODE_ENABLED)
                if(value.to_i == 1)
                  config_hash[directive] = true
                else
                  config_hash[directive] = false
                end
              elsif(directive == TARGET_LANG_BLACKLIST)
                  
                #add each lang to our blacklist hash
                value.split(',').each{ |lang|
                  config_hash[directive][lang] = 1 
                }

              elsif(!value)
                config_hash[directive] = ""
              else
                config_hash[directive] = value
              end
            else
              MyLogger.instance.debug("Config", "Ignoring unknown directive #{directive}" )
            end

          else
            MyLogger.instance.debug("Config", "Ignoring malformed config directive #{directive} => #{value}" )
          end

        else
          MyLogger.instance.debug("Config", "Ignoring comment line #{line}" )
        end
      end
    end
    
    return config_hash
  end  
  
  def config_sanity_check(config)
    
    #start with simple stuff
    raise ConfigError.new("Both CPU and GPU code are disabled") unless
      config[CPU_TRANSCODE_ENABLED] or config[CPU_TRANSCODE_ENABLED]
    
    #resolve ffmpeg resources
    #if binary location is not defined
    
    transcoder_binary_location = config[TRANSCODER_BINARY_LOCATION]
    transcoder_probe_binary_location = config[TRANSCODER_PROBE_BINARY_LOCATION]
      
    #validate the location of the transcoder binary /opt/ffmpeg/bin/ffmpeg
    if(!transcoder_binary_location)
      #whereis ffmpeg
      MyLogger.instance.debug("Config", "Transcoder binary directive undefined. Looking for ffmpeg")    
      bin_location = `whereis -b ffmpeg`.split(/\ /)[1]
  
      if( bin_location && File.exists?(bin_location))
        #overwrite the directive with what whereis found if it's viable
        config[TRANSCODER_BINARY_LOCATION] = bin_location
        MyLogger.instance.debug("Config", "Using ffmpeg at #{bin_location}")
      end
    end
    
    #validate the directive is set
    raise ConfigError.new("Cannot find FFmpeg binary") unless 
      config[TRANSCODER_BINARY_LOCATION] and 
      File.exists?(config[TRANSCODER_BINARY_LOCATION])

    #validate the location of the transcoder probe binary /opt/ffmpeg/bin/ffprobe
    if(!transcoder_probe_binary_location)
      #whereis ffprobe
      MyLogger.instance.debug("Config", "Transcoder probe binary directive undefined. Looking for ffprobe")
      bin_location = `whereis -b ffprobe`.split(/\ /)[1]

      if( bin_location && File.exists?(bin_location))
        config[TRANSCODER_PROBE_BINARY_LOCATION] = bin_location
        MyLogger.instance.debug("Config", "Using ffprobe at #{bin_location}")
      end
    end

    #validate the directive is set
    raise ConfigError.new("Cannot find FFprobe binary") unless 
      config[TRANSCODER_PROBE_BINARY_LOCATION] and 
      File.exists?(config[TRANSCODER_PROBE_BINARY_LOCATION])
      
    #if gpu enabled and no hwaccel? -> see if possible
    #raise "No hwaccel specified" unless 
    #  get_gpu_transcode_enabled and !get_gpu_hwaccel
      
    #validate target directives are set
    raise FormatError.new("Target video format not specified") unless
      config[TARGET_VIDEO_FORMAT]
      
    raise FormatError.new("Target audio format not specified") unless
      config[TARGET_AUDIO_FORMAT]
      
    raise FormatError.new("Target pixel format not specified") unless
      config[TARGET_PIXEL_FORMAT]
      
    raise FormatError.new("Target file format not specified") unless
      config[TARGET_FILE_EXTENSION]
      
    raise LangError.new("Target language not specified") unless
      config[TARGET_LANG]
  end
  
  def system_sanity_check
    #ffmpeg encoders/decoders/codecs check
    #we know target formats by this point. is conversion possible?
    #can we convert to our target format?
    
    #load_functions succeeded by this point
    
    #actionable errors. problems here likely mean something
    #like libx264 is not installed, or support is not compiled in to ffmpeg
    
    #can we write to/encode in target video format? 
    #can't worry about reading, since at this point we don't know inputs
    
    #encoder is libx264 or h264_nvenc depending on gpu/cpu
    #associated format is "h264"
    #have to somehow resolve encoder lib from format (h264)
    
    if(get_cpu_transcode_enabled)
      
      #can do we support encoding to the target video format?
      #do we know the library to invoke for the transcode? libx264 for h264, libx265 for hevc
      
      #get_target_video_format is human readable like "h264"
      #@config[SUPPORTED_ENCODERS][SUPPORTED_ENCODERS_VIDEO]
        #libx264 => "V..X.WTF"
      
#      "supported_encoders": {
#        "video": {
#          ...
#          "libx264": "V.....",
      
      #resolve transcode lib from VIDEO_TRANSCODE_ENCODERS_CPU and get_target_video_format
      #exception if no entry in transcode libs hash
      set_target_video_format(get_target_video_format)

      MyLogger.instance.debug("Config", "Resolved CPU target transcode library #{get_target_video_cpu_encoder} from format #{get_target_video_format}")      
    else
      MyLogger.instance.debug("Config", "CPU Transcoding disabled, skipping transcode support check")   
    end 
    
    if(get_gpu_transcode_enabled)    

      

      
      #check hwaccels are available too
      #ffmpeg -hwaccels
      #Enabled hwaccels:
#      Hardware acceleration methods:
#      cuda
#      cuvid
      NVIDIA_HW_ACCELS.each{ |accel| 
        raise ConfigError.new("Expected GPU hw accel not found: #{accel}") unless
          @config[SUPPORTED_HW_ACCELS][accel]
      }
      
      #check for a specified hw accel and if it's valid
      raise ConfigError.new("Unknown GPU hw accel specified") unless 
        @config[GPU_HWACCEL] && @config[SUPPORTED_HW_ACCELS][@config[GPU_HWACCEL]]
      
      #can we encode to target format?
      gpu_transcode_encoder = VIDEO_TRANSCODE_ENCODERS_GPU[get_target_video_format]
      raise FormatError.new("Cannot resolve GPU transcode library from format #{get_target_video_format}") unless
        gpu_transcode_encoder
      
      raise FormatError.new("Cannot encode video with GPU to target format") unless 
        @config[SUPPORTED_ENCODERS][SUPPORTED_ENCODERS_VIDEO][gpu_transcode_encoder] 
      
      #set transcode lib config directive 
      @config[TARGET_VIDEO_GPU_TRANSCODE_ENCODER] = gpu_transcode_encoder
      
      MyLogger.instance.debug("Config", "Resolved GPU target transcode library #{transcode_lib} from format #{get_target_video_format}")      
    else
      MyLogger.instance.debug("Config", "GPU Transcoding disabled, skipping target transcode support check")      
    end
    
    #######################################  
    #can we write to/encode in target audio format? 
    #no gpu/cpu choice here
    
    set_target_audio_format(get_target_audio_format)
    
    MyLogger.instance.debug("Config", "Resolved target audio encoder #{get_target_audio_encoder} from format #{get_target_audio_format}")      

      
    #######################################  
    #can we write to/encode in target pixel format?
    #no encoder persay
    #IO... yuv420p 
    #no gpu/cpu choice here      
    set_target_pixel_format(get_target_pixel_format)
    
    #######################################  
    #can we write to/encode in target subtitle format? 
    #skip for now
      
    #######################################  
    #can we write to/encode in target file format? 
    #check formats for default file extension
    #shaky to try and map extension to format name
    #
    #raise "Cannot write to target file format" unless
    #  @config[SUPPORTED_FILE_FORMATS][get_target_file_format] =~ /^.E/

  end
  
  def get_transcoder_binary_location
    return @config[TRANSCODER_BINARY_LOCATION]
  end
  
  def get_transcoder_probe_binary_location
    return @config[TRANSCODER_PROBE_BINARY_LOCATION]
  end

  def get_cpu_transcode_enabled
    return @config[CPU_TRANSCODE_ENABLED]
  end

  def get_gpu_transcode_enabled
    return @config[GPU_TRANSCODE_ENABLED]
  end
  
  def get_gpu_hwaccel
    return @config[GPU_HWACCEL]
  end
  
  def get_target_lang
    return @config[TARGET_LANG]
  end
  
  def get_target_lang_blacklist
    return @config[TARGET_LANG_BLACKLIST]
  end

  def get_target_video_format
    return @config[TARGET_VIDEO_FORMAT]
  end
  
  def get_target_audio_format
    return @config[TARGET_AUDIO_FORMAT]
  end
  
  def get_target_video_encoder
    #TODO: make cpu/gpu agnostic
    return @config[TARGET_VIDEO_CPU_TRANSCODE_ENCODER]
  end
  
  def get_target_file_format
    return @config[TARGET_FILE_EXTENSION]
  end

  def get_target_pixel_format
    return @config[TARGET_PIXEL_FORMAT]
  end
  
  def get_target_video_gpu_encoder
    return @config[TARGET_VIDEO_GPU_TRANSCODE_ENCODER]
  end  

  def get_target_video_cpu_encoder
    return @config[TARGET_VIDEO_CPU_TRANSCODE_ENCODER]
  end  
  
  def get_target_audio_encoder
    return @config[TARGET_AUDIO_TRANSCODE_ENCODER]
  end  

  def get_supported_encoders
    return @config[SUPPORTED_ENCODERS]
  end

  def get_supported_decoders
    return @config[SUPPORTED_DECODERS]
  end

  def get_supported_pixel_formats
    return @config[SUPPORTED_PIXEL_FORMATS]
  end

  def get_supported_file_formats
    return @config[SUPPORTED_FILE_FORMATS]
  end

  def get_supported_file_extensions
    return @config[SUPPORTED_FILE_EXTENSIONS]
  end


  
  def get_audio_encoder_info(encoder)
    raise "Can't get info for invalid audio encoder #{encoder}" unless
      encoder and
      @config[SUPPORTED_ENCODERS][SUPPORTED_ENCODERS_AUDIO][encoder]
    
      return @config[SUPPORTED_ENCODERS][SUPPORTED_ENCODERS_AUDIO][encoder]
  end
  
  def get_video_encoder_info(encoder)
    raise "Can't get info for invalid video encoder #{encoder}" unless
      encoder and
      @config[SUPPORTED_ENCODERS][SUPPORTED_ENCODERS_VIDEO][encoder]
  
    return @config[SUPPORTED_ENCODERS][SUPPORTED_ENCODERS_VIDEO][encoder]
  end
  
###############################
  
  def load_encoders(config)
    #should have viable ffmpeg at this point
    #encoders are the writers to the target format
    output = `#{config[TRANSCODER_BINARY_LOCATION]} -v 0 -encoders | tail -n +11`
    
    #Encoders:
    #V..... = Video
    #A..... = Audio
    #S..... = Subtitle
    #.F.... = Frame-level multithreading
    #..S... = Slice-level multithreading
    #...X.. = Codec is experimental
    #....B. = Supports draw_horiz_band
    #.....D = Supports direct rendering method 1
    #------
    #V..... a64multi             Multicolor charset for Commodore 64 (codec a64_multi)
    #V..... a64multi5            Multicolor charset for Commodore 64, extended with 5th color (colram) (codec a64_multi5)

    raise ConfigError.new("Attempt to load encoders failed") unless output
    
    encoders = {
        SUPPORTED_ENCODERS_VIDEO => Hash.new,
        SUPPORTED_ENCODERS_AUDIO => Hash.new,
        SUPPORTED_ENCODERS_SUBTITLE => Hash.new
    }
    
    output.split("\n").each { |line| 
      line.strip!
      fields = line.split("\s")
      
      #encoder line -> decide v/a/s and store
      if(fields[0] and fields[1])
        if(fields[0][0] == "V")
          encoders[SUPPORTED_ENCODERS_VIDEO][fields[1]] = fields[0]
        elsif(fields[0][0] == "A")
          encoders[SUPPORTED_ENCODERS_AUDIO][fields[1]] = fields[0]
        elsif(fields[0][0] == "S")
          encoders[SUPPORTED_ENCODERS_SUBTITLE][fields[1]] = fields[0]
        else
          MyLogger.instance.debug("Config", "Malformed encoder entry #{line}")
        end
        
      end
    }
    video_encoders_loaded = encoders[SUPPORTED_ENCODERS_VIDEO].length
    MyLogger.instance.debug("Config", "Loaded #{video_encoders_loaded} video encoders")
    raise ConfigError.new("Could not load video encoders") unless 
      video_encoders_loaded > 0
    
    audio_encoders_loaded = encoders[SUPPORTED_ENCODERS_AUDIO].length 
    MyLogger.instance.debug("Config", "Loaded #{audio_encoders_loaded} audio encoders")
    raise ConfigError.new("Could not load audio encoders") unless 
      audio_encoders_loaded > 0

    subtitle_encoders_loaded = encoders[SUPPORTED_ENCODERS_SUBTITLE].length
    MyLogger.instance.debug("Config", "Loaded #{subtitle_encoders_loaded} subtitle encoders")
    raise ConfigError.new("Could not load subtitle encoders") unless 
      subtitle_encoders_loaded > 0
      
    return encoders
  end
  
  def load_decoders(config)
    #should have viable ffmpeg at this point
    #decoders are the readers of the source format
    output = `#{config[TRANSCODER_BINARY_LOCATION]} -v 0 -decoders | tail -n +11`
    
    #Decoders:
    #V..... = Video
    #A..... = Audio
    #S..... = Subtitle
    #.F.... = Frame-level multithreading
    #..S... = Slice-level multithreading
    #...X.. = Codec is experimental
    #....B. = Supports draw_horiz_band
    #.....D = Supports direct rendering method 1
    #------
    #V..... a64multi             Multicolor charset for Commodore 64 (codec a64_multi)
    #V..... a64multi5            Multicolor charset for Commodore 64, extended with 5th color (colram) (codec a64_multi5)
  
    decoders = {
        SUPPORTED_DECODERS_VIDEO => Hash.new,
        SUPPORTED_DECODERS_AUDIO => Hash.new,
        SUPPORTED_DECODERS_SUBTITLE => Hash.new
      
    }
    
    raise "Attempt to load encoders failed" unless output
   
    output.split("\n").each { |line| 
      line.strip!
      fields = line.split("\s")
      
      #encoder line -> decide v/a/s and store
      if(fields[0] and fields[1])
        if(fields[0][0] == "V")
          decoders[SUPPORTED_DECODERS_VIDEO][fields[1]] = fields[0]
        elsif(fields[0][0] == "A")
          decoders[SUPPORTED_DECODERS_AUDIO][fields[1]] = fields[0]
        elsif(fields[0][0] == "S")
          decoders[SUPPORTED_DECODERS_SUBTITLE][fields[1]] = fields[0]
        else
          MyLogger.instance.debug("Config", "Malformed decoder entry #{line}")
        end
        
      end
    }
    
    if(get_gpu_transcode_enabled)
      #check decoders too, even though there shouldn't be an nvidia format
      #maybe the decode process itself matters
      #      V..... h264_cuvid           Nvidia CUVID H264 decoder (codec h264)
      #      V..... hevc_cuvid           Nvidia CUVID HEVC decoder (codec hevc)
      #      V..... mjpeg_cuvid          Nvidia CUVID MJPEG decoder (codec mjpeg)
      #      V..... mpeg1_cuvid          Nvidia CUVID MPEG1VIDEO decoder (codec mpeg1video)
      #      V..... mpeg2_cuvid          Nvidia CUVID MPEG2VIDEO decoder (codec mpeg2video)
      #      V..... mpeg4_cuvid          Nvidia CUVID MPEG4 decoder (codec mpeg4)
      #      V..... vc1_cuvid            Nvidia CUVID VC1 decoder (codec vc1)
      #      V..... vp8_cuvid            Nvidia CUVID VP8 decoder (codec vp8)
      #      V..... vp9_cuvid            Nvidia CUVID VP9 decoder (codec vp9)
      NVIDIA_DECODERS.each{ |decoder| 
        raise ConfigError.new("Expected GPU decoder not found: #{decoder}") unless
          @config[SUPPORTED_DECODERS][SUPPORTED_DECODERS_VIDEO][decoder]
      }
    end
    
    video_decoders_loaded = decoders[SUPPORTED_DECODERS_VIDEO].length
    MyLogger.instance.debug("Config", "Loaded #{video_decoders_loaded} video decoders")
    raise "Could not load video decoders" unless video_decoders_loaded > 0
        
    audio_encoders_loaded = decoders[SUPPORTED_DECODERS_AUDIO].length
    MyLogger.instance.debug("Config", "Loaded #{audio_encoders_loaded} audio decoders")
    raise "Could not load audio encoders" unless audio_encoders_loaded > 0
    
    subtitle_encoders_loaded = decoders[SUPPORTED_DECODERS_SUBTITLE].length
    MyLogger.instance.debug("Config", "Loaded #{subtitle_encoders_loaded} subtitle decoders")
    raise "Could not load subtitle encoders" unless subtitle_encoders_loaded > 0
  end
  
  def load_file_formats(config)
    #should have viable ffmpeg at this point
    #formats are the file structures ffmpeg can interact with
    #file structures organize stream and metadata
    #demuxing -> read from
    #muxing -> write to
    output = `#{config[TRANSCODER_BINARY_LOCATION]} -v 0 -formats | tail -n +5`
    
#    File formats:
#     D. = Demuxing supported
#     .E = Muxing supported
#     --
#     D  3dostr          3DO STR
#      E 3g2             3GP2 (3GPP2 file format)
#      E 3gp             3GP (3GPP file format)
#     D  4xm             4X Technologies
#     E a64             a64 - video for Commodore 64
#    D  aa              Audible AA format files
#    D  aac             raw ADTS AAC (Advanced Audio Coding)
#    DE ac3             raw AC-3

    raise "Attempt to load formats failed" unless output
    
    file_formats =  Hash.new
    
    output.split("\n").each { |line| 
      line.strip!
      fields = line.split("\s")
      
      if(fields[0] and fields[1])
        file_formats[fields[1]] = fields[0]
      else
        MyLogger.instance.debug("Config", "Malformed format line #{line}")
      end
    }
    
    formats_loaded = file_formats.length
    MyLogger.instance.debug("Config", "Loaded #{formats_loaded} formats")
    raise "Could not load formats" unless formats_loaded > 0
    
    return file_formats
  end
  
  def load_pixel_formats(config)
    #should have viable ffmpeg at this point
    #formats are the something of the something else
    output = `#{config[TRANSCODER_BINARY_LOCATION]} -v 0 -pix_fmts | tail -n +9`

    #  Pixel formats:
    #  I.... = Supported Input  format for conversion
    #  .O... = Supported Output format for conversion
    #  ..H.. = Hardware accelerated format
    #  ...P. = Paletted format
    #  ....B = Bitstream format
    #  FLAGS NAME            NB_COMPONENTS BITS_PER_PIXEL
    #  -----
    #  IO... yuv420p                3            12
    #  IO... yuyv422                3            16
    #  IO... rgb24                  3            24

    raise "Attempt to load pixel formats failed" unless output
    
    pix_formats = {
      SUPPORTED_PIXEL_FORMATS => Hash.new
    }
    
    output.split("\n").each { |line| 
      line.strip!
      fields = line.split("\s")
      
      if(fields[0] and fields[1])        
        pix_formats[fields[1]] = fields[0]
      else
        MyLogger.instance.debug("Config", "Malformed pixel format entry #{line}")        
      end
    }
    
    pixel_formats_loaded = pix_formats.length
    MyLogger.instance.debug("Config", "Loaded #{pixel_formats_loaded} pixel formats")
    raise "Could not load pixel formats" unless pixel_formats_loaded > 0
    
    return pix_formats
  end
  
  def load_transcode_targets
    
    #devices to transcode for
    
    #conf files at conf/targets/*.conf
    #results into @config[TRANSCODE_TARGETS]
    
    
    #can we write to target audio format?
    #can we write to target pix format?
    
  end

  def is_valid_target_video_format(format)
        
    raise FormatError.new("Can't validate nil video format") unless format 
    
    isValidCPU = false
    isValidGPU = false
    
    #possible to have 1 but not the other?
    if get_cpu_transcode_enabled
      cpu_transcode_encoder = VIDEO_TRANSCODE_ENCODERS_CPU[format]
            
      raise FormatError.new("Cannot resolve CPU target transcode library from format #{format}") unless
        cpu_transcode_encoder
      
      #check if the lib is in the encoders list
      #exception if otherwise
      raise FormatError.new("Cannot encode video with CPU to target format") unless 
        @config[SUPPORTED_ENCODERS][SUPPORTED_ENCODERS_VIDEO][cpu_transcode_encoder] 
        
      #set transcode lib config directive 
      #@config[TARGET_VIDEO_CPU_TRANSCODE_ENCODER] = cpu_transcode_encoder
      isValidCPU = true
    end
    
    if get_gpu_transcode_enabled
      
      gpu_transcode_encoder = VIDEO_TRANSCODE_ENCODERS_GPU[format]
            
      raise FormatError.new("Cannot resolve GPU target transcode library from format #{format}") unless
        gpu_transcode_encoder
      
      #check if the lib is in the encoders list
      #exception if otherwise
      raise FormatError.new("Cannot encode video with GPU to target format") unless 
        @config[SUPPORTED_ENCODERS][SUPPORTED_ENCODERS_VIDEO][gpu_transcode_encoder] 
      
      isValidGPU = true
    end
    
    return (isValidCPU or isValidGPU)
  end
  
  def is_valid_target_audio_format(format)
    #does an encoder exist?
    #can we resolve the transcode lib?
    #does the transcode info (A.OHX)
    
    raise FormatError.new("Can't validate nil video format") unless format 

   
    raise FormatError.new("Cannot resolve target transcode library from format #{format}") unless
      AUDIO_TRANSCODE_ENCODERS[format]
    
    #resolve encoder
    encoder = AUDIO_TRANSCODE_ENCODERS[format]
    
    return (
      encoder and 
      @config[SUPPORTED_ENCODERS][SUPPORTED_ENCODERS_AUDIO][encoder] and
      @config[SUPPORTED_ENCODERS][SUPPORTED_ENCODERS_AUDIO][encoder] =~ /^A.*/
    )
    
  end
  
  def is_valid_target_pixel_format(format)
    #is this in the pixel formats list?
    
    return ( 
      format and 
      @config[SUPPORTED_PIXEL_FORMATS][format] and 
      @config[SUPPORTED_PIXEL_FORMATS][format] =~ /^.O/
    )
  end
  
  def is_valid_target_lang(lang)
    #is this not on the blacklist?
    return (lang and !@config[TARGET_LANG_BLACKLIST][lang])
  end
  
  def set_target_video_format(format)
    raise FormatError.new("Cannot transcode with new target video format #{format}") unless
      is_valid_target_video_format(format)
    
    #set config directives    
    @config[TARGET_VIDEO_FORMAT] = format
    MyLogger.instance.debug("Config", "Setting new target video format to #{format}")

    
    #do we have an encoder for this format?    
    #TODO: unfuck this. an install can have both cpu/gpu enabled and want a cpu encode
    if(get_gpu_transcode_enabled)
      video_transcode_lib = VIDEO_TRANSCODE_ENCODERS_GPU[format] 
      
      raise FormatError.new("Cannot resolve transcode library from format #{format}") unless
        video_transcode_lib

      @config[TARGET_VIDEO_GPU_TRANSCODE_ENCODER] = video_transcode_lib
      MyLogger.instance.debug("Config", "Setting new target video encoder to #{video_transcode_lib}")

      
    else
      video_transcode_lib = VIDEO_TRANSCODE_ENCODERS_CPU[format] 
      
      raise FormatError.new("Cannot resolve transcode library from format #{format}") unless
        video_transcode_lib

      @config[TARGET_VIDEO_CPU_TRANSCODE_ENCODER] = video_transcode_lib
      MyLogger.instance.debug("Config", "Setting new target video encoder to #{video_transcode_lib}")
    end
  end
  
  def set_target_audio_format(format)
    
    raise FormatError.new("Cannot transcode with new target audio format #{format}") unless
      is_valid_target_audio_format(format)
    
    #set config directives
    @config[TARGET_AUDIO_FORMAT] = format
    
    MyLogger.instance.debug("Config", "Setting new target audio format to #{format}")

   
    #also qualified by is_valid_target_audio_format
    audio_transcode_lib = AUDIO_TRANSCODE_ENCODERS[format] 
    @config[TARGET_AUDIO_TRANSCODE_ENCODER] = audio_transcode_lib
    MyLogger.instance.debug("Config", "Setting new target audio encoder to #{audio_transcode_lib}")

    
  end
  
  def set_target_pixel_format(format)
    raise FormatError.new("Cannot transcode with new target pixel format #{format}") unless
      is_valid_target_pixel_format(format)

    @config[TARGET_PIXEL_FORMAT] = format
  end
  
  def set_target_lang(lang)
    #not much to check since this doesn't depend on an ffmpeg install
    #check if not on the blacklist
    raise LangError.new("Attempting to set target language to blacklisted language") unless 
      is_valid_target_lang(lang)
    
    @config[TARGET_LANG] = lang
  end
  
  def set_target_file_extension(extension)
    
  end

  def dump_config
    return JSON.pretty_generate(@config)
  end

end
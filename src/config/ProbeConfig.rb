require 'logger'
require 'json'

require_relative "../log/MyLogger.rb"
require_relative "../exceptions/LangError.rb"
require_relative "../exceptions/FormatError.rb"
require_relative "../exceptions/ConfigError.rb"

class ProbeConfig

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
  
  DEFAULT_CONFIG_FILE = "#{ File.dirname(__FILE__) }/../../conf/dlnaify.conf"

  attr_accessor :config, :probe_conf_file
  def initialize(conf_file = DEFAULT_CONFIG_FILE )

    #if we have a default we might as well accept nil as a param
    
    if(conf_file)
      @probe_conf_file = conf_file
    else
      @probe_conf_file =  DEFAULT_CONFIG_FILE
    end
    
    raise ConfigError.new("Invalid config file") unless @probe_conf_file && File.exists?(@probe_conf_file)
    
    #read dlnaify.conf in dir
    #set defaults
    #load directives
    
    #sanitize conf file path
    MyLogger.instance.debug("ProbeConfig", "Loading config from directory #{@probe_conf_file}")

    @config = load_config(@probe_conf_file)
    
    #core directives dlnaify.conf
    
    #ffmpeg binaries
    #check config directives for values
    
    ####################
    #after this point, we can continue to build the config
    #provided what we already have is coherent
    
    #these load functions require viable binaries for ffmpeg and ffprobe
    
    #load encoders
    @config[SUPPORTED_ENCODERS] = load_encoders
    
    #load decoders
    @config[SUPPORTED_DECODERS] = load_decoders
    
    #load formats
    @config[SUPPORTED_FILE_FORMATS] = load_file_formats
    
    #load pixel formats
    @config[SUPPORTED_PIXEL_FORMATS] = load_pixel_formats

    #####################
    
    #assemble the config for the final validation
    
    config_sanity_check
    
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
          TRANSCODER_NAME => nil,  #required
          TRANSCODER_BINARY_LOCATION => nil, #required
          TRANSCODER_PROBE_BINARY_LOCATION => nil, #required
          SUPPORTED_ENCODERS => nil,
          SUPPORTED_DECODERS => nil,
          SUPPORTED_FILE_FORMATS => nil,
          SUPPORTED_FILE_EXTENSIONS => nil,
          SUPPORTED_PIXEL_FORMATS => nil,
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
  
  def config_sanity_check
    
    #start with simple stuff
    raise ConfigError.new("Both CPU and GPU code are disabled") unless
      @config[CPU_TRANSCODE_ENABLED] or @config[CPU_TRANSCODE_ENABLED]
    
    #resolve ffmpeg resources
    #if binary location is not defined
    
    transcoder_binary_location = @config[TRANSCODER_BINARY_LOCATION]
    transcoder_probe_binary_location = @config[TRANSCODER_PROBE_BINARY_LOCATION]
      
    #validate the location of the transcoder binary /opt/ffmpeg/bin/ffmpeg
    if(!transcoder_binary_location)
      #whereis ffmpeg
      MyLogger.instance.debug("Config", "Transcoder binary directive undefined. Looking for ffmpeg")    
      bin_location = `whereis -b ffmpeg`.split(/\s+/)[1]
  
      if( bin_location && File.exists?(bin_location))
        #overwrite the directive with what whereis found if it's viable
        config[TRANSCODER_BINARY_LOCATION] = bin_location
        MyLogger.instance.debug("Config", "Using ffmpeg at #{bin_location}")
      end
    end
    
    #validate the directive is set
    raise ConfigError.new("Cannot find FFmpeg binary") unless 
      @config[TRANSCODER_BINARY_LOCATION] and 
      File.exists?(@config[TRANSCODER_BINARY_LOCATION])

    #validate the location of the transcoder probe binary /opt/ffmpeg/bin/ffprobe
    if(!transcoder_probe_binary_location)
      #whereis ffprobe
      MyLogger.instance.debug("Config", "Transcoder probe binary directive undefined. Looking for ffprobe")
      bin_location = `whereis -b ffprobe`.split(/\s+/)[1]

      if( bin_location && File.exists?(bin_location))
        @config[TRANSCODER_PROBE_BINARY_LOCATION] = bin_location
        MyLogger.instance.debug("Config", "Using ffprobe at #{bin_location}")
      end
    end

    #validate the directive is set
    raise ConfigError.new("Cannot find FFprobe binary") unless 
          @config[TRANSCODER_PROBE_BINARY_LOCATION] and 
          File.exists?(@config[TRANSCODER_PROBE_BINARY_LOCATION])
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

  ############
  #Decoders
  
  def get_supported_decoders
    return @config[SUPPORTED_DECODERS]
  end
  
  def get_supported_video_decoders
    return @config[SUPPORTED_DECODERS][SUPPORTED_DECODERS_VIDEO]
  end

  def get_supported_audio_decoders
    return @config[SUPPORTED_DECODERS][SUPPORTED_DECODERS_AUDIO]
  end

  def get_supported_subtitle_decoders
    return @config[SUPPORTED_DECODERS][SUPPORTED_DECODERS_SUBTITLE]
  end
      
  ############
  #Encoders

  def get_supported_encoders
    return @config[SUPPORTED_ENCODERS]
  end
  
  def get_supported_video_encoders
    return @config[SUPPORTED_ENCODERS][SUPPORTED_ENCODERS_VIDEO]
  end
  
  def get_supported_audio_encoders
    return @config[SUPPORTED_ENCODERS][SUPPORTED_ENCODERS_AUDIO]
  end
  
  def get_supported_subtitle_encoders
    return @config[SUPPORTED_ENCODERS][SUPPORTED_ENCODERS_SUBTITLE]
  end
  
  ############
  #other supported fields
  
  def get_supported_pixel_formats
    return @config[SUPPORTED_PIXEL_FORMATS]
  end

  def get_supported_file_formats
    return @config[SUPPORTED_FILE_FORMATS]
  end

  def get_supported_file_extensions
    return @config[SUPPORTED_FILE_EXTENSIONS]
  end
  
###############################
  
  def load_encoders
    #should have viable ffmpeg at this point
    #encoders are the writers to the target format
    output = `#{@config[TRANSCODER_BINARY_LOCATION]} -v 0 -encoders | tail -n +11`
    
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
      
      #V... h1337
      (capability, encoder)  = line.split("\s")
      
      #encoder line -> decide v/a/s and store
      if(capability and encoder)
        if(capability[0] == "V")
          encoders[SUPPORTED_ENCODERS_VIDEO][encoder] = capability
        elsif(capability[0] == "A")
          encoders[SUPPORTED_ENCODERS_AUDIO][encoder] = capability
        elsif(capability[0] == "S")
          encoders[SUPPORTED_ENCODERS_SUBTITLE][encoder] = capability
        else
          MyLogger.instance.debug("ProbeConfig", "Malformed encoder entry #{line}")
        end
        
      end
    }
    video_encoders_loaded = encoders[SUPPORTED_ENCODERS_VIDEO].length
    MyLogger.instance.debug("ProbeConfig", "Loaded #{video_encoders_loaded} video encoders")
    raise ConfigError.new("Could not load video encoders") unless 
      video_encoders_loaded > 0
    
    audio_encoders_loaded = encoders[SUPPORTED_ENCODERS_AUDIO].length 
    MyLogger.instance.debug("ProbeConfig", "Loaded #{audio_encoders_loaded} audio encoders")
    raise ConfigError.new("Could not load audio encoders") unless 
      audio_encoders_loaded > 0

    subtitle_encoders_loaded = encoders[SUPPORTED_ENCODERS_SUBTITLE].length
    MyLogger.instance.debug("ProbeConfig", "Loaded #{subtitle_encoders_loaded} subtitle encoders")
    raise ConfigError.new("Could not load subtitle encoders") unless 
      subtitle_encoders_loaded > 0
      
    return encoders
  end
  
  def load_decoders
    #should have viable ffmpeg at this point
    #decoders are the readers of the source format
    output = `#{@config[TRANSCODER_BINARY_LOCATION]} -v 0 -decoders | tail -n +11`
    
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
    
    raise "Attempt to load decoders failed" unless output
   
    output.split("\n").each { |line| 
      line.strip!
      
      #V... h1337
      (capability, decoder) = line.split("\s")
      
      #encoder line -> decide v/a/s and store
      if(decoder and capability)
        if(capability[0] == "V")
          decoders[SUPPORTED_DECODERS_VIDEO][decoder] = capability
          #puts "Video decoder #{ decoder }"
        elsif( capability[0] == "A")
          decoders[SUPPORTED_DECODERS_AUDIO][decoder] = capability
        elsif( capability[0] == "S")
          decoders[SUPPORTED_DECODERS_SUBTITLE][decoder] = capability
        else
          MyLogger.instance.debug("ProbeConfig", "Malformed decoder entry #{line}")
        end
        
      end
    }

    video_decoders_loaded = decoders[SUPPORTED_DECODERS_VIDEO].length
    MyLogger.instance.debug("ProbeConfig", "Loaded #{video_decoders_loaded} video decoders")
    raise "Could not load video decoders" unless video_decoders_loaded > 0
        
    audio_decoders_loaded = decoders[SUPPORTED_DECODERS_AUDIO].length
    MyLogger.instance.debug("ProbeConfig", "Loaded #{audio_decoders_loaded} audio decoders")
    raise "Could not load audio encoders" unless audio_decoders_loaded > 0
    
    subtitle_decoders_loaded = decoders[SUPPORTED_DECODERS_SUBTITLE].length
    MyLogger.instance.debug("ProbeConfig", "Loaded #{subtitle_decoders_loaded} subtitle decoders")
    raise "Could not load subtitle decoders" unless subtitle_decoders_loaded > 0
    
    return decoders
  end
  
  def load_file_formats
    #should have viable ffmpeg at this point
    #formats are the file structures ffmpeg can interact with
    #file structures organize stream and metadata
    #demuxing -> read from
    #muxing -> write to
    output = `#{@config[TRANSCODER_BINARY_LOCATION]} -v 0 -formats | tail -n +5`
    
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
        MyLogger.instance.debug("ProbeConfig", "Malformed format line #{line}")
      end
    }
    
    formats_loaded = file_formats.length
    MyLogger.instance.debug("ProbeConfig", "Loaded #{formats_loaded} formats")
    raise "Could not load formats" unless formats_loaded > 0
    
    return file_formats
  end
  
  def load_pixel_formats
    #should have viable ffmpeg at this point
    #formats are the something of the something else
    output = `#{@config[TRANSCODER_BINARY_LOCATION]} -v 0 -pix_fmts | tail -n +9`

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
    
    pix_formats =  Hash.new
    
    output.split("\n").each { |line| 
      line.strip!
      (capability, format)  = line.split("\s")
      
      if(capability and format)        
        pix_formats[format] = capability
      else
        MyLogger.instance.debug("ProbeConfig", "Malformed pixel format entry #{line}")        
      end
    }
    
    pixel_formats_loaded = pix_formats.length
    MyLogger.instance.debug("ProbeConfig", "Loaded #{pixel_formats_loaded} pixel formats")
    raise "Could not load pixel formats" unless pixel_formats_loaded > 0
    
    return pix_formats
  end

  def get_conf_file
    return @probe_conf_file
  end
  
  def dump_config
    return JSON.pretty_generate(@config)
  end

end
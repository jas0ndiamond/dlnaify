require_relative 'VideoStream.rb'
require_relative 'AudioStream.rb'

#Create MediaFiles with context provided by Config
class MediaFileFactory
  
  attr_accessor :config
  def initialize(config)
    @config = config
    
    #puts @config.dump_config
    
    MyLogger.instance.debug("MediaFileFactory", "Hi it's me, the MediaFileFactory")

  end
  
  def build_media_file(path, dest)
    
    start_time = Time.now.to_f
    
    #determine if our ffmpeg can read the file format supplied
    
    #sanitize path and dest. common fail case is an apostrophe
    
    
    #initialize
    media_file = MediaFile.new(path,dest, transcoder_probe(path))
    
    #report stream findings
    MyLogger.instance.debug("MediaFileFactory", "Found #{media_file.transcoder_probe_info["streams"].length} streams")

    
    #config-context operations
    
    #query video streams
    #frame count and pixel format are tied to this
    set_video_format(media_file)
    
    #query audio streams
    set_audio_format(media_file)
    
    #set_subtitle_format(media_file)
    
    #TODO: use config to set dest extension with target file extension
    
    end_time = Time.now.to_f
    
    MyLogger.instance.info("MediaFileFactory", "MediaFile build took #{(end_time-start_time)} s")
    
    return media_file
  end
  
  def transcoder_probe(file)
    #this should be fast. shouldn't decode the file
    #this should also fail if ffprobe doesn't have a demuxer for the input file
    #this function is is MediaFileFactory because it needs access to config and 
    # the transcoder binary
    syscall = [
      @config.get_transcoder_probe_binary_location,
      "-v",
      "error",
      "-show_format",
      "-show_streams",
      "-print_format",
      "json",
      "'#{file}'"
    ].join(" ")
    
    #run the syscall, if retval is bad, then likely we don't have a viable demuxer
    #otherwise attempt to json-parse the output
    
    output = ""
    Open3.popen3(syscall) {|stdin, stdout, stderr, wait_thr|        
      if(wait_thr.value != 0)
        
        MyLogger.instance.error("MediaFileFactory", "Transcoder probe failed with syscall #{syscall}")

        
        raise "Could not open #{file} with transcoder. Unsupported file format?"
      end
        
      output = stdout.read
    }
    
    return JSON.parse(output)
  end
  
  def set_video_format(mediaFile) 
    #determine number of video streams
    #problem if > 1
        
    #get video stream and respective format, pixel format, and frame count
        
    video_streams = Array.new
    stream_count = 0
    
    #for each stream, we need to load and store the id, format, and pixel format
    mediaFile.transcoder_probe_info["streams"].each{ |stream|
     if(stream["codec_type"] == "video")
       
       #determine the container framecount. 
       #see if there is a field for this
       #do not decode the file unless absolutely necessary
       frame_count = 0
       if( stream["nb_frames"] and stream["nb_frames"] != 0)
         frame_count = stream["nb_frames"]
         MyLogger.instance.info("MediaFileFactory", "Using frame count from nb_frames: #{frame_count}")
       elsif(stream["tags"] and stream["tags"]["NUMBER_OF_FRAMES"] and stream["tags"]["NUMBER_OF_FRAMES"] != 0)
         frame_count = stream["tags"]["NUMBER_OF_FRAMES"]
         MyLogger.instance.info("MediaFileFactory", "Using frame count from tags/NUMBER_OF_FRAMES: #{frame_count}")
       else
         
         #no obvious way of determining frame count. 
         #decode the file and count frames
         #very slow
         syscall = [
           @config.get_transcoder_probe_binary_location,
           "-v",
           "error",
           "-count_frames",
           "-select_streams",
           "v:0",
           "-show_entries",
           "stream=nb_read_frames",
           "-of",
           "default=nokey=1:noprint_wrappers=1",
           "'#{mediaFile.path}'"
         ].join(" ")
             
         frame_count = `#{syscall}`.chomp.to_i
         MyLogger.instance.info("MediaFileFactory", "Found frame count from decode: #{frame_count}")
       end
       
       found_stream = VideoStream.new(
         stream_count, stream["index"],stream["codec_name"],stream["pix_fmt"], frame_count
       )
       
       stream_count += 1
       
       MyLogger.instance.info("MediaFileFactory", "Found video stream #{found_stream.to_s}")
           
       #mediaFile.add_video_stream(found_stream)
       video_streams.push(found_stream)
     end
    }
    
    #at this point we have all video streams. we need to settle on our top choice
    #store the stream count. we'll need this to determine stream index offsets
    #===>not needed if we keep track of this in the stream itself
    
    #MyLogger.instance.info("MediaFileFactory", "Found #{video_streams.length} video streams")    
    
    #if there's only one, then it's an easy choice
    if(video_streams.length == 1)
      MyLogger.instance.info("MediaFileFactory", "Found single target video stream #{video_streams[0].to_s}")
      mediaFile.set_video_stream(video_streams[0])
    else
      MyLogger.instance.info("MediaFileFactory", "Determining target video stream")

      #TODO: implement method of choosing video stream if there are multiple
      #largest resolution?
      #longest duration?
      #https://superuser.com/questions/650291/how-to-get-video-duration-in-seconds/945604#945604
      #largest frame count?
      
      #remove streams from mediafile object?
      #store array locally then add to mediafile after this iftest?
      
      #for now, just choose the first one we find. dlna does that already
      mediaFile.set_video_stream(video_streams[0])
    end
    
    raise "Could not find suitable video stream for #{mediaFile.path}" unless 
      mediaFile.get_video_stream
       
    #when this function returns, format/framecount/etc should be testable
  end

  def set_audio_format(mediaFile)
    #get all audio streams
    
    #determine number of streams
    #query each one
    #add each one
    
    #for each stream, we need to load and store the 
    #id, format, and lang

    #we are targeting 1 vid stream and 1 audio stream
    #vid stream will be stream #0.0, audio will be stream #0.1
    audio_streams = Array.new
    stream_count = 1
    
    mediaFile.transcoder_probe_info["streams"].each{ |stream|
     if(stream["codec_type"] == "audio")
       
       language = "unknown"
       
       #language may not be specified
       if(stream["tags"] and stream["tags"]["language"])
         language = stream["tags"]["language"]
       end
       
       found_stream = AudioStream.new(
         stream_count, stream["index"],language,stream["codec_name"]
       )
       stream_count += 1
       
       MyLogger.instance.info("MediaFileFactory", "Found audio stream #{found_stream.to_s}")
           
       #mediaFile.add_audio_stream(found_stream)
       audio_streams.push(found_stream)
       
     end
    }
    
    #at this point we have all audio streams. we need to settle on our top choice
    #===>not needed if we keep track of this in the stream itself

    #MyLogger.instance.info("MediaFileFactory", "Found #{audio_streams.length} audio streams")
    #mediaFile.set_audio_stream_count(audio_streams.length)
    
    #if there's only one, then it's an easy choice
    #even if it's blacklisted?
    if(audio_streams.length == 1)
      MyLogger.instance.info("MediaFileFactory", "Found single target audio stream #{audio_streams[0].to_s}")
      mediaFile.set_audio_stream(audio_streams[0])
    else
      MyLogger.instance.info("MediaFileFactory", "Determining target audio streams")

      
      #target lang?
      audio_streams.each{ |as|
        if(as.lang.downcase == @config.get_target_lang.downcase )
          MyLogger.instance.info("MediaFileFactory", "Adding audio stream for whitelisted language: #{as.to_s}")
          mediaFile.set_audio_stream(as)
          break
        end
      }
      
      #if still no good audio streams...
      if(!mediaFile.audio_stream)
        #langs not on blacklist
        #case insensitive match
        audio_streams.each{ |as|
          blacklisted = false
          @config.get_target_lang_blacklist.each { |blacklist_lang, dummy|
            if(as.lang.downcase == blacklist_lang.downcase)
              blacklisted = true
              MyLogger.instance.info("MediaFileFactory", "Skipping audio stream for blacklisted language: #{as.to_s}")
              break
            end
          }
          
          if(!blacklisted)
            MyLogger.instance.info("MediaFileFactory", "Adding audio stream for non-blacklisted language: #{as.to_s}")
            mediaFile.set_audio_stream(as)
          end
        }
      end
      
    raise LangError.new("Could not find suitable audio stream for #{mediaFile.path}") unless 
      mediaFile.get_audio_stream
    end
    
    #when this function returns, format/lang/etc should be testable
  end
  
#  def set_pixel_format(mediaFile)
#    
#  end    
  
  def set_subtitle_format(mediaFile)
    
  end
  
end
require_relative 'MyLogger.rb'

require 'open3'

class MediaFile
  
  attr_accessor :path
  attr_accessor :dest
  attr_accessor :transcoder_probe_info
  attr_accessor :converted_frame_count
  attr_accessor :framerate
  attr_accessor :status
  attr_accessor :syscall
  attr_accessor :message
  
  #these are the streams currently existing in the file that will be chosen/set by MediaFileFactory
  #video will be the chosen video stream
  #audio will be the chose audio stream
  attr_accessor :video_stream
  attr_accessor :audio_stream
  
  def initialize(path, dest, transcoder_probe_info="{}")

    #path is the source file
    #dest is the destination file
    
    raise Errno::ENOENT.new("Source file not found") unless 
      path != nil and 
      path != "" and
      File.exists?(path) and 
      File.readable?(path)
    
    # @path needs to be escaped, since it's used in system calls later
    #replace this with canonical path
    #don't use safe path
    @path = File.realpath(path) #File.path(path).gsub(/\"/, "\\\"" )
      
    MyLogger.instance.debug("MediaFile", "Received path #{@path}")
    
    #check dest's parent exists and is writable
    raise Errno::ENOENT.new("Destination not accessible") unless 
      dest != nil and 
      dest != "" and
      File.exists?( File.dirname(dest) ) and
      File.writable?( dest )
    
    #dest needs canonical path
    @dest = File.realpath(dest)
    
    MyLogger.instance.debug("MediaFile", "Received dest #{@dest}")
    
    @video_stream = nil    
    @audio_stream = nil
    
    @transcoder_probe_info = transcoder_probe_info
    
    update_converted_frame_count(0)
    update_framerate(0)
    set_status("QUEUED")
  end
  
  def update_converted_frame_count(count)
    
    if count =~ /\d+/    
      Mutex.new.synchronize do
        @converted_frame_count = count
      end
    else
      #MyLogger.instance.warn("MediaFile", "Ignoring bad converted frame count update")
    end
  end
  
  def set_status(status)
    Mutex.new.synchronize do
      @status = status
    end
  end
  
  def get_status
    status = ""
    
    Mutex.new.synchronize do
      status = @status
    end
    
    return status
  end
  
  def set_video_stream(stream)
    Mutex.new.synchronize do
      @video_stream = stream
    end
  end
    
  def set_audio_stream(stream)
    Mutex.new.synchronize do
      @audio_stream = stream
    end
  end
  
  def get_video_stream
    val = nil
    Mutex.new.synchronize do
      val = @video_stream
    end
    return val
  end
  
  def get_audio_stream
    val = nil
    Mutex.new.synchronize do
      val = @audio_stream
    end
    return val
  end
  
  def get_video_format
    return get_video_stream.format
  end
  
  def get_audio_format
    return get_audio_stream.format
  end
  
  def get_total_frame_count
    get_video_stream.frame_count
  end
  
  def get_converted_frame_count
    val = 0
    
    Mutex.new.synchronize do
      val = @converted_frame_count
    end
    
    return val
  end
  
  def get_framerate
    val = 0
    
    Mutex.new.synchronize do
      val = @framerate
    end
    
    return val
  end
  
  def update_framerate(rate)
    return unless rate =~ /\d+/
    
    Mutex.new.synchronize do
      @framerate = rate
    end
  end
  
  def get_safe_dest_path
    
    #safe dest for this file is determined by the @dest dir and 
    #the source file name
    #both need to be cleaned
    
    #expand file into full path
    my_dest = File.realpath(@dest)
    
    #get and clean source filename
    my_filename = File.basename(@path).
      gsub(/(,|;|'|`|")/,"").
      gsub(/^\[[^\]]*\]/,""). 
      gsub(/^\([^\]]*\)/,""). 
      gsub(/^(_|\ )/, "").
      gsub(/^\./, "")
    
    #remove odd chars
  
    #remove preceding ^\[*\]
      
    #remove leading parens
      
    #remove quotes
      
    #remove apostrophes
  
    #last step is remove preceding '.' do not want to create hidden files
    
    #puts "Found filename #{path}"

    result = "#{my_dest}/#{my_filename}"
    
    MyLogger.instance.debug("MediaFile", "get_safe_dest_path returning #{result}")
    
    return result
  end
  
end
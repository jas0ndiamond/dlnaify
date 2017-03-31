class MediaFile
  
  attr_accessor :path, :dest, :converted_frame_count, :total_frame_count, :framerate, :status, :syscall, :message
  
  def initialize(path, dest)
    
    #@path needs to be escaped, since it's used in system calls later
    
    @path = File.path(path).gsub(/\"/, "\\\"")
    @dest = dest
    
    puts @path
    
    
    @media_info = `/usr/bin/mediainfo --fullscan \"#{@path}\"`.split(/\n/)
    
    @video_info = Array.new
    collect = false
    @media_info.each{ |line| 
      
      if( line =~ /^Video\s*$/) 
        collect = true
      elsif (collect)
        break if line =~ /^\s*$/
        @video_info.push(line)
      end
    }
          
    @video_info.each_with_index { |line|
      puts line
        
      if( line !~ /^\s*$/ && line.include?(":"))
        directive = line.split(/\:/)
        key = directive[0].strip
        value = directive[1].strip
    
        if( key == "NUMBER_OF_FRAMES" or key == "Frame count" )
      
          @total_frame_count = value.chomp
          break
        end
      end 
    } 
       
    #raise "Could not determine frame count for file #{@path}" unless @total_frame_count
    @total_frame_count = "???" unless @total_frame_count
    
    @converted_frame_count = 0
    @framerate = 0
    @status = "QUEUED"
  end
    
  def update_converted_frame_count(count)
    
    if count =~ /\d+/    
      Mutex.new.synchronize do
        @converted_frame_count = count
      end
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
  
end
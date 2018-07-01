require_relative "MediaFile.rb"
require 'pty'
require 'expect'
require 'curses'

#target extension matters? go with mp4 for h264
VIDEO_CONV_OPTS =
{
  "hevc" => "-c:v libx264", #nothing, dest file as mp4 is enough
  "hevc (Main) yuv420p" => "-c:v libx264",
  "hevc (Main 10) yuv420p10le" => "-c:v libx264",
  "hevc (Main 10) yuv420p10le(tv)" => "-c:v libx264",
  "libx264 yuv420p" => "-c:v copy", # "copy", is faster
  "h264 (High 10) yuv420p10le" => "-c:v libx264",
  "h264 (High) yuv420p" => "-c:v copy", 
  "mpeg4 (Simple Profile) yuv420p" => ""
}

AUDIO_CONV_OPTS =
{
  "vorbis" => "-strict experimental -c:a:0 aac",
  "ac3" => "-c:a copy",
  "aac" => "-strict experimental -c:a copy",   #aac is desired, but apparently needs strict experimental. copy, not transcode
  "aac (LC)" => "-strict experimental -c:a copy", 
  "mp3" => "-strict experimental -c:a:0 aac",
  "flac"=> "-strict experimental -c:a:0 aac"
}

SCREEN_HEIGHT      = 80
SCREEN_WIDTH       = 130
HEADER_HEIGHT      = 1
HEADER_WIDTH       = SCREEN_WIDTH
MAIN_WINDOW_HEIGHT = SCREEN_HEIGHT - HEADER_HEIGHT
MAIN_WINDOW_WIDTH  = SCREEN_WIDTH

class Converter

  attr_accessor :all_files, :num_threads
  def initialize(num_threads = 1, files_to_convert = nil )
    @queued_files = Queue.new
    @all_files = Array.new
    @num_threads = num_threads

    if files_to_convert
      files_to_convert.each do |file|
        add_file(file)
      end
    end
  end

  def add_file(path, dest = ".")

    dest = "." if dest == nil

    new_file = MediaFile.new(path, dest)
      
    #puts "Added file #{new_file.path}"
    
    @queued_files.push(new_file)
    @all_files.push(new_file)
  end

  def run

    workers = (@num_threads).times.map do
      Thread.new do
        while !@queued_files.empty?
          #avconv convert
          convert_file(@queued_files.pop)

        end
      end
    end
    
    Curses.noecho
    Curses.nonl
    Curses.stdscr.keypad(true)
    Curses.raw
    Curses.stdscr.nodelay = 1
    
    Curses.init_screen
    
    Curses.start_color
    
    Curses.init_pair(2, Curses::COLOR_BLACK, Curses::COLOR_GREEN)
    Curses.init_pair(3, Curses::COLOR_BLACK, Curses::COLOR_WHITE)

    window = Curses::Window.new(60, MAIN_WINDOW_WIDTH, 1, 0)
    
    window.scrollok(true)
    window.idlok(true)
    
    #window.color_set(1)
    
    window.setpos(MAIN_WINDOW_HEIGHT - 1, 0)
    
    #add thread to oversee file conversion status
    monitor = Thread.new do
      
      done = Array.new
      failed = Array.new
      queued = Array.new
      process = Array.new
      unexpected = Array.new
      
      sleep 5
      
      begin
        #while all files are not done or failed
        sleep 2
        
        done.clear
        failed.clear
        queued.clear
        process.clear
        unexpected.clear
        
        #puts "Starting status grab"
        
        @all_files.each { |file|
          
          status = file.get_status
          
          filename = File.basename(file.path)
          
          if(status == "QUEUED")
            queued.push("#{filename}...#{status}")
          elsif(status == "DONE")
            done.push("#{filename}...#{status}")          
          elsif(status == "FAILED")
            failed.push("#{filename}...#{status}")   
          elsif(status == "PROCESS")
            
            frame_count = file.get_converted_frame_count
            
            #test/SampleVideo_1280x720_5mb2.mkv...^[[0m^[[0;33m[libx264/658 @ 0xf7c6a0]fps
            #test/SampleVideo_1280x720_5mb2.mkv...682/658 @ 23fps

            if(frame_count =~ /\d+/)
              process.push("#{filename}...#{frame_count}/#{file.total_frame_count} @ #{file.get_framerate} fps")
            else
              process.push("#{filename}...PROCESSING")
            end
            

          else
            unexpected.push("#{filename}: Unexpected file status: #{status}" )   
          end
          
        } 
        
        #puts "finished status grab"
        
        #curses print out
        
        output = ""
        
        done.each { |str| 
         output << str << "\n"
        }
        
        queued.each { |str| 
         output << str << "\n"
        }
        
        failed.each { |str| 
         output << str << "\n"
        }
        
        process.each { |str| 
          output << str << "\n"
        }
        
        unexpected.each { |str| 
          output << str << "\n"
        }
        
        output << "#{Time.now}\n================================\n"
        
        #puts output
        window.clear
        window << output
        window.refresh
    
      end until queued.size == 0 && process.size == 0
      
      window.close
      Curses.close_screen

      #print status
            
      done.clear
      failed.clear
      output = ""
      
      @all_files.each { |file|
        
        status = file.get_status
        filename = File.basename(file.path)
        
        if(status == "DONE")
          done.push( "#{filename}...#{status}" )        
        elsif(status == "FAILED")
          failed.push( "#{filename}...#{status}\n==>#{file.message}\n==>#{file.syscall}" )
        end   
      }
      
      done.each { |str| 
       output << str << "\n"
      }
      
      output << "================================\n"
      
      failed.each { |str| 
       output << str << "\n"
      }
      
      puts "#{output}\n\nConversion completed"
          
    end

    workers.map(&:join)   
    monitor.join
  end

  def get_dest_filename(path)
    #remove odd chars

    #remove preceding ^\[*\]

    #puts "Found filename #{path}"

    #determine if we need to convert to mp4
    
    #return File.basename(path).gsub(/(,|;|'|`)/,"").gsub(/^\[[^\]]*\]/,"").gsub(/\.mkv$/,".mp4").gsub(/^(_|\ )/, "")
    return File.basename(path).gsub(/(,|;|'|`)/,"").gsub(/^\[[^\]]*\]/,"").gsub(/^(_|\ )/, "").gsub(/^\./, "")

  end

  def convert_file(file)

    return if file == nil

    file.status = "PROCESS"
    
    begin
      #probe file
      file_info = probe_file(file.path)
  
      #get video stream
      #    Stream #0.0(eng): Video: h264 (High 10), yuv420p10le, 1280x720 [PAR 1:1 DAR 16:9], 23.98 fps, 1k tbn, 47.95 tbc (default)
      #    Stream #0.0(jpn): Video: h264 (High 10), yuv420p10le, 1280x720 [PAR 1:1 DAR 16:9], 23.98 fps, 1k tbn, 47.95 tbc (default)
      #    Stream #0.0: Video: hevc (Main), yuv420p, 1280x720, PAR 1:1 DAR 16:9, 23.98 fps, 1k tbn, 23.98 tbc (default)
  
      #determine video codec
      #puts "video stream: #{file_info["video"][0]}"
  
      video_codec = get_video_codec(file_info)
      raise "Could not determine video codec from #{file_info}" unless video_codec
      
      #puts "Found video codec #{video_codec}"
      
      #check if we have to convert the video
      video_options = VIDEO_CONV_OPTS[video_codec]
      raise "Could not determine video options from codec '#{video_codec}'" unless video_options
            
      #get audio stream
      stream_number = get_audio_stream_number(file_info)
      raise "Could not determine target audio stream number from #{ file_info["audio"] }" unless stream_number
      
      #puts "Using audio stream number #{stream_number}"
      audio_map ="-map 0:0 -map 0:#{stream_number}"
  
      #get audio codec
      audio_codec = get_audio_codec(file_info)
      raise "Could not determine audio codec" unless audio_codec
          
      #puts "Found audio codec #{audio_codec}"
  
      #check if we have to convert the audio
      audio_options = AUDIO_CONV_OPTS[audio_codec]
      raise "Could not determine audio options from codec '#{audio_codec}'" unless audio_options
      
      #check if the file should already play. only convert it if necessary
      
      
      target = "#{file.dest}/#{get_dest_filename(file.path)}"
  
      #verify parameters are defined
  
      #raise "Could not find suitable audio stream" unless
  
      syscall = "avconv -y -i \"#{file.path}\" #{audio_map} #{video_options} #{audio_options} \"#{target}\" 2>&1"
      #puts syscall
  
      file.syscall = syscall
      
      #`#{syscall}'
      
      #continuously read from stdout to get current converted framecount and fps. possibly modify num_threads if fps breaks range
      
      PTY.spawn( syscall ) do |stdout, stdin, pid|
        begin
          
          #puts "Waiting for ctrl-c prompt"
          
          stdout.expect(/Press ctrl-c to stop encoding/, 10) do
            #nothing, skip the data avconv prints before starting conversion
          end
          
          #puts "Waiting for 'frame=' Encoding started"
          
          while(!stdout.closed? && !stdin.closed?)
            #stdout.each { |line| puts "Got line: #{line}" }
          
            sleep 10
            
            #grab the next result            
            stdin.puts("\r")
              
            stdout.expect(/frame=/, 3) do |result|

              #found frameinfo ["28946 fps=  2 q=28.0 size=  198817kB time=1205.20 bitrate=1351.4kbits/s    \r\e[0m\e[0;39mframe="]
              if(result)
                fields = result[0].split("\s")
                converted_frames = fields[0]
                framerate = fields[2]
                
                if(converted_frames =~ /\d+/)
                  file.update_converted_frame_count(converted_frames)
                  file.update_framerate(framerate)
                else
                  #likely the first iteration
                  file.update_converted_frame_count(0)
                  file.update_framerate(0)
                end
                
                #puts "found frameinfo #{result}\nconverted: #{converted_frames}/#{file.total_frame_count}\nrate: #{framerate}"
              end         
            end
            
            #sleep? the process is running, don't have to keep hammering it with /r
            #make sure the right thing is sleeping           
            
          end
        rescue Errno::EIO => e
          puts "Errno:EIO error, but this probably just means that the process has finished giving output #{e.message}"
        rescue => e
          
          #file status to shit
          file.status = "FAILED: #{e}"
        ensure
          Process.wait(pid)  
        end 
        
      end
    end

    status = $?
    
    #update file status to done
    if( status == 0 )
      file.status = "DONE"
    else
      file.message = status
      file.status = "FAILED"      
    end
    #puts "Exit code #{status}"
    
    #puts "Conversion exits with status #{status}"
    
  end

  def get_audio_codec(file_info)
    return file_info["audio"][0].split(" ")[2].gsub(/,/, "")
  end

  def get_audio_stream_number(file_info)

    puts "audio stream: #{file_info["audio"][0]}"

    #figure out audio stream of english track and map it to first audio stream of target
    #Stream #0.1(eng): Audio: aac, 44100 Hz, stereo, fltp (default)
    #Stream #0.2(jpn): Audio: aac, 48000 Hz, stereo, fltp
    #Stream #0.3(eng): Subtitle: ass (default)
    #Stream #0.1: Audio: aac, 48000 Hz, 5.1, fltp (default)
        
    
    #0.1: Audio: aac, 48000 Hz, stereo, fltp (default)
    
    return nil unless file_info["audio"][0]
    
    stream_number = file_info["audio"][0].split(" ")[0].split("\.")[1]
      
    return nil unless stream_number
      
    #remove any language string
    stream_number.gsub!(/(\(.*\))/, "")
      
    #remove trailing semicolon
    stream_number.gsub!(/\:$/, "")
      
    return stream_number
  end

  def get_video_codec(file_info)

    raise "Could not determine video codec" unless file_info["video"][0]
    
    #0.0: Video: h264 (High 10), yuv420p10le, 960x720 [PAR 1:1 DAR 4:3], 23.98 fps, 1k tbn, 47.95 tbc (default)
    return file_info["video"][0].gsub(/^.*\ Video:\ /,"").split(",")[0..1].join("")
  end

  def probe_file(file)
    results = Hash.new

    if File.exists?(file)
      #redirect stderr to stdout. avconv prints most everything to stderr
      raw_info = `avconv -i \"#{file}\" 2>&1`

      #interested in video stream and audio streams

      i = 0
      results["video"] = Array.new

      #probably only want/going to get one video stream
      raw_info.split("\n").grep(/^\s*Stream\ \#.*Video.*/).each { |vstream|
        results["video"][i] = vstream.to_s.gsub(/^\s*Stream\ \#/, "")
      }

      results["audio"] = Array.new

      #only match english stream
      i = 0
      raw_info.split("\n").grep(/^\s*Stream\ \#.*Audio.*/).each{ |astream|
        
        if astream.match(/.*(eng).*/)
          results["audio"][i] = astream.to_s.gsub(/^\s*Stream\ \#/, "")
          i+=1
        end 
      }

      if(results["audio"].length == 0)       
        i=0
        #if no eng audio stream was found, match non-jpn/fra/esp prefixes
        raw_info.split("\n").grep(/^\s*Stream\ \#.*Audio.*/).each{ |astream|
          if !astream.match(/.*(jpn|fra|ita|esp|pol).*/)
            results["audio"][i] = astream.to_s.gsub(/^\s*Stream\ \#/, "") 
            i+=1
          end
        }

      end
    else
      puts "Source file #{file} does not exist"
    end

    #return hash of video and audio stream info
    return results
  end

end
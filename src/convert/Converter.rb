require_relative "MediaFile.rb"
require_relative "MediaFileFactory.rb"
require_relative "../convert/ConvertJobFactory.rb"
require_relative '../log/MyLogger.rb'

require 'pty'
require 'expect'
require 'curses'

SCREEN_HEIGHT      = 80
SCREEN_WIDTH       = 130
HEADER_HEIGHT      = 1
HEADER_WIDTH       = SCREEN_WIDTH
MAIN_WINDOW_HEIGHT = SCREEN_HEIGHT - HEADER_HEIGHT
MAIN_WINDOW_WIDTH  = SCREEN_WIDTH

class Converter

  attr_accessor :all_files, :num_threads
  def initialize(config, num_threads = 1, files_to_convert = nil )
    @config = config
    
    @queued_files = Queue.new
    
    @all_files = Array.new
    
    @media_file_factory = MediaFileFactory.new(@config)
    
    @convert_job_factory = ConvertJobFactory.new(@config)
    
    #TODO: update this later on
    #@pty_refresh = @config.get_pty_refresh
    
    #TODO: maybe do a sanity check on thread count here
    #reconcile with cpu count if cpu transcode is going to happen
    #num threads < num files
    #num threads < 2x cpu core count
    #num threads => 1 if gpu transcode
    @num_threads = num_threads

    
    MyLogger.instance.info("Converter", "Initialized with #{num_threads} threads")

    
    if files_to_convert
      files_to_convert.each { |file|
        add_file(file)
      }
    end
  end

  def add_file(path, dest = ".")

    dest = "." if dest == nil

    new_file = @media_file_factory.build_media_file(path, dest)
      
    MyLogger.instance.info("Converter", "Added file #{new_file.path}")
    
    convertJob = @convert_job_factory.build_convert_job(new_file)
    
    @queued_files.push(convertJob)
    @all_files.push(convertJob)
  end

  def run

    MyLogger.instance.info("Converter", "Running conversion")

    if @queued_files.empty?
      
      MyLogger.instance.warn("Converter", "Running conversion with 0 files added. Terminating Conversion.")

      puts "\n\nConversion completed"
      
      return
    end
    
    workers = (@num_threads).times.map do
      Thread.new do
        while !@queued_files.empty?          
          
          #MyLogger.instance.info("Converter", "Running conversion job for #{convertJob.media_file.path}")
          
          #convertJob.run

          new_job = @queued_files.pop
          
          new_job.run
          
          
          
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
    
    #set our colors
    #window.color_set(1)
    
    window.setpos(MAIN_WINDOW_HEIGHT - 1, 0)
    
    quit = false
    
    #catch 'q' to terminate conversion
    quitThread = Thread.new do
      
      loop do
        case Curses.getch
        when "q"
          MyLogger.instance.info("Converter", "Aborting conversion triggered by user input")
          
          quit = true
          Curses.addstr("quitting")
          
          break
        end
      end      
    end
    
    #add thread to oversee file conversion status
    monitor = Thread.new do
      
      #TODO: this isn't always printed
      output = "Initializing..."
      
      window.clear
      window << output
      window.refresh
      
      done = Array.new
      failed = Array.new
      queued = Array.new
      process = Array.new
      unexpected = Array.new
      
      #TODO: why are we sleeping here? giving ffmpeg a chance to spin up?
      sleep 3
      
      window.clear
      window.refresh
      
      begin
        #while all files are not done or failed
        #sleep 2
        
        done.clear
        failed.clear
        queued.clear
        process.clear
        
        #TODO: this is a stop gap until we get a better handle on status management
        unexpected.clear
        
        #puts "Starting status grab"
        
        #in progress convertjobs
        @all_files.each { |file|
          
          #TODO: why sleep here? to not hammer the cpu?
          sleep 1
          
          #puts "Queued file: #{file.media_file.path}"
          
          status = file.media_file.get_status
          
          #retrieve readablename from MediaFile
          filename = File.basename(file.media_file.path)
     
          #puts "Status grab #{filename} => #{status}"
               
          if(status == "QUEUED")
            queued.push("#{filename}...#{status}")
          elsif(status == "DONE")
            done.push("#{filename}...#{status}")          
          elsif(status == "FAILED")
            failed.push("#{filename}...#{status}")   
          elsif(status == "PROCESS")
            
            #puts "stats start"
            
            #TODO: possibly modify num_threads if fps breaks threshold
            
            frame_count = file.media_file.get_converted_frame_count
            total_frame_count = file.media_file.get_total_frame_count
            frame_rate = file.media_file.get_framerate
            
            #puts "stats end"
            
            #test/SampleVideo_1280x720_5mb2.mkv...^[[0m^[[0;33m[libx264/658 @ 0xf7c6a0]fps
            #test/SampleVideo_1280x720_5mb2.mkv...682/658 @ 23fps

            #output << "found frame count: #{frame_count}\n"
            #output << "found total frame count: #{total_frame_count}\n"
            #output << "found frame rate: #{frame_rate}\n"
            
            if(frame_count =~ /\d+/)
              
              process.push("#{filename}...#{frame_count}/#{total_frame_count} @ #{frame_rate} fps")
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
        
        output << "#{Time.now}\n"
        output << "Press 'q' to quit\n================================\n"
        
        window.clear
        window << output
        window.refresh
    
      end until quit || (queued.size == 0 && process.size == 0)

      window.close
      Curses.close_screen

      if(quit)
        #MyLogger.instance.info("Converter", "Conversion terminated. Cleaning up")
        
        #for each convertjob, terminate syscall
        
        puts "Conversion terminated by user. Cleaning up"
        MyLogger.instance.warn("Converter", "Conversion terminated by user. Cleaning up")
        
        #signal to the converter jobs to kill their respective ffmpeg syscalls
        #TODO: kind of sloppy to just call cancel on all media_files and trust that 
        #       it's handled correctly. maybe ConvertJob should subclass Thread 
        @all_files.map(&:cancel)
        
        workers.map(&:exit)
        
      else
        MyLogger.instance.info("Converter", "Conversion completed")
      end
            
      ##############
      #conversion completed/terminated by this point
      
      done.clear
      failed.clear
      report = ""
      
      #print the results of the conversion
      @all_files.each { |file|
        
        status = file.media_file.get_status
        filename = File.basename(file.media_file.path)
        
        if(status == "FAILED")
          
          #clean this up
          
          failed.push( "#{filename}...#{status}\n==>#{file.message}\n==>#{file.syscall}" )
        else
          if(status == "QUEUED")
            #don't do anything, file is already in queued list          
          elsif( status == "DONE" )
            done.push( "#{filename}...#{status}" )          
          else
            #anything that isn't queued or done is failed. namely processing/cancelled/failed
            failed.push( "#{filename}...#{status}" )
          end
        end   
      }
      
      report << "================================\nQUEUED:\n"
      
      #if we got to all the jobs, this should be empty
      queued.each { |str| 
        report << str << "\n"
      }
      
      report << "================================\nDONE:\n"
      
      done.each { |str| 
        report << str << "\n"
      }
      
      report << "================================\nFAILED:\n"
      
      failed.each { |str| 
        report << str << "\n"
      }
      report << "================================\n"
      
      #print to stdout, since the curses window is closed earlier
      puts "#{report}\n\nConversion completed"
          
    end

    workers.map(&:join) 
    
    quitThread.join  
    
    monitor.join
  end
end
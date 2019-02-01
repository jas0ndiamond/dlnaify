require_relative "MediaFile.rb"
require_relative "MediaFileFactory.rb"
require_relative "ConvertJobFactory.rb"
require_relative 'MyLogger.rb'

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

    workers = (@num_threads).times.map do
      Thread.new do
        while !@queued_files.empty?

          #TODO: migrate to convertjob
          #convert_file(@queued_files.pop)
          
          
          
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
    
    #window.color_set(1)
    
    window.setpos(MAIN_WINDOW_HEIGHT - 1, 0)
    
    quit = false
    
    #catch 'q' to terminate conversion
    quitThread = Thread.new do
      #MyLogger.instance.info("Converter", "Starting quit listener")
      
      loop do
        case Curses.getch
        when "q"
          quit = true
          Curses.addstr("quitting")
          
          #puts "Quitting"
          
          #MyLogger.instance.info("Converter", "Aborting conversion triggered by user input")
          
          
          break
        end
      end
      
      #MyLogger.instance.info("Converter", "Exiting quit listener")
      
      #puts "Exiting quit listener"
      
    end
    
    #add thread to oversee file conversion status
    monitor = Thread.new do
      
      output = "Initializing..."
      
      window.clear
      window << output
      window.refresh
      
      done = Array.new
      failed = Array.new
      queued = Array.new
      process = Array.new
      unexpected = Array.new
      
      #TODO: why are we sleeping here?
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
        unexpected.clear
        
        #puts "Starting status grab"
        
        #in progress convertjobs
        @all_files.each { |file|
          
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
        
        #puts output
        window.clear
        window << output
        window.refresh
    
      end until quit || (queued.size == 0 && process.size == 0)
      


      
      window.close
      Curses.close_screen

      if(quit)
        #MyLogger.instance.info("Converter", "Conversion terminated. Cleaning up")
        
        #for each convertjob, terminate syscall
        
        puts "Conversion terminated. Cleaning up"
        
        #signal to the converter jobs to kill their respective ffmpeg syscalls
        workers.map(&:cancel)
        
        workers.map(&:exit)
        
      else
        #MyLogger.instance.info("Converter", "Conversion completed")
      end
            
      done.clear
      failed.clear
      output = ""
      
      #print the results of the conversion
      @all_files.each { |file|
        
        status = file.media_file.get_status
        filename = File.basename(file.media_file.path)
        
        if(status == "FAILED")
          
          #clean this up
          
          failed.push( "#{filename}...#{status}\n==>#{file.message}\n==>#{file.syscall}" )
        else
          if(status != "DONE")
            queued.push( "#{filename}...#{status}" )          
          else
            done.push( "#{filename}...#{status}" )          
          end
        end   
      }
      
      #if we got to all the jobs, this should be empty
      queued.each { |str| 
       output << str << "\n"
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
    
    #TODO: need to join explicitly? pretty sure
    quitThread.join  
    
    monitor.join
  end
end
require 'pty'
require 'expect'

require_relative "MediaFile.rb"
require_relative 'MyLogger.rb'

class ConvertJob
  
  attr_accessor :media_file
  attr_accessor :syscall
  attr_accessor :output
  attr_accessor :exit_code
  attr_accessor :converter_pid
  attr_accessor :cancelled
  
  def initialize(media_file)
    raise "MediaFile not defined" unless media_file
    
    @media_file = media_file
    
    @cancelled = false
    
    #do we really need output? would be packed full of the frame updates
    #exit code might be enough, along with any exception messages
    @output = ""
  end
  
  def cancel()
    @cancelled = true
  end
  
  def set_syscall(syscall)
    @syscall = syscall
  end
  
  def run
    #execute syscall here
    #file is MediaFile
    
    raise "Syscall not defined" unless @syscall
    raise "MediaFile not defined" unless @media_file

    MyLogger.instance.info("ConvertJob", "Running ConvertJob for #{@media_file.path}")

    #inital status. everything is PROCESS until started
    @media_file.set_status("PROCESS")
    
    begin      
      #continuously read from stdout to get current converted framecount and fps. 
      
      #puts "ConvertJob syscall: #{@syscall}"
      MyLogger.instance.info("ConvertJob", "ConvertJob syscall for #{@media_file.path}: #{@syscall}")
      
      PTY.spawn( @syscall ) { |stdout, stdin, pid|
        begin
          
          @converter_pid = pid
          
          MyLogger.instance.info("ConvertJob", "Received pid #{@converter_pid} for conversion of #{@media_file.path}")
          
          #puts "=================================\nSyscall Read: #{stdout.read}"
          while(!stdout.closed?)
            
            #puts "before result"
            sleep 1
            
            #ffmpeg now has a sort of command shell, spamming '?' prints the menu
            #should work with older versions, which accepted just \r
            stdin.puts("?\r")
            
            stdout.expect(/^frame=/, timeout=3) { |result|
              #puts "result: #{result}"
              #result: ["   36 fps= 13 q=0.0 size=       2kB time=00:00:01.65 bitrate=  11.4kbits/s speed=0.608x    \rkey    function\r\n?      show this help\r\n+      increase verbosity\r\n-      decrease verbosity\r\nc      Send command to first matching filter supporting it\r\nC      Send/Queue command to all matching filters\r\nD      cycle through available debug modes\r\nh      dump packets/hex press to cycle through the 3 states\r\nq      quit\r\ns      Show QP histogram\r\nframe="]

              if(result)
                fields = result[0].split("\s")
                converted_frames = fields[0]

                #get converted frame count from output
                #if we can't get the frame count, probably not worth trying for other data
                if(converted_frames =~ /\d+/)
                  @media_file.update_converted_frame_count(converted_frames)
                  
                  #get framerate from output
                  #frame rate can be presented as fps=0.0 or fps= 4 or fps=33 or fps= 44
                  #if fields[1] =~ fps=\ ==> framecount = fields[3]
                  #if fields[1] =~ fps=\d ==> framecount = fields[2].substr("fps=".length)
                  framerate = 0
                  if( fields[1] =~ /fps=\ /)
                    framerate = fields[2]
                  elsif (fields[1] =~ /fps=\d/)
                    framerate = fields[1].gsub!("fps=", "")
                  elsif (fields[1] == "fps=")
                    framerate = fields[2] unless fields[2] !~ /\d+/
                  else
                    MyLogger.instance.warn("ConvertJob", "Ignoring bad framerate update '#{fields[1]}'")
                  end
                  
                  @media_file.update_framerate(framerate)
                  
                else
                  #likely the first iterations
                  
                  MyLogger.instance.warn("ConvertJob", "Ignoring bad frame count update '#{converted_frames}'")
                  
                  @media_file.update_converted_frame_count(0)
                  @media_file.update_framerate(0)
                end

                #puts "found frameinfo #{result}\nconverted: #{converted_frames}/#{@media_file.get_total_frame_count}\nrate: #{@media_file.get_framerate}"
             else
                MyLogger.instance.warn("ConvertJob", "Ignoring bad stdout update")

             end 
              
            }

            #puts "after result"
          end
          
          #puts "stdout of syscall closed" 
          
        rescue Errno::EIO => e
          MyLogger.instance.debug("ConvertJob", "Errno:EIO error, but this probably just means that the process has finished giving output #{e.message}")
        rescue => e
          MyLogger.instance.error("ConvertJob", "ConvertJob for #{@media_file.path} failed with #{e.message}")       
          #file status to shit
          @media_file.set_message("FAILED: #{e}")
        ensure
          #if the thread that ConvertJob runs in is exited, this executes
          
          #only wait if we haven't cancelled the job
          if (!@cancelled)
            MyLogger.instance.info("ConvertJob", "Waiting for pid: #{@converter_pid} to exit") 
          
            Process.wait(@converter_pid)
          else
            #cancelled so don't wait
          end
          
          MyLogger.instance.info("ConvertJob", "Pid: #{@converter_pid} has exited")
        end 
        
      }     

    end

    if(!@cancelled)
      @exit_code = $?
       
      MyLogger.instance.info("ConvertJob", "Exit code: #{exit_code}")
      
      #update file status to done
      if( @exit_code == 0 )
        @media_file.set_status("DONE")
      else
        @media_file.set_status("FAILED")      
      end   
    else
      #if it's cancelled we don't care about the exit code
      
      
    end
    
    MyLogger.instance.info("ConvertJob", "Conversion exits with status: #{@media_file.get_status}") 
  end
end
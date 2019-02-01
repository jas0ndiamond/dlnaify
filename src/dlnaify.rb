require 'find'
require_relative 'Converter.rb'

####################################################

#unhardcode or make comprehensive
#https://askubuntu.com/questions/844711/how-can-i-find-all-video-files-on-my-system
#FILE_FMTS = ["mkv", "mp4", "avi", "mpg", "m4v", "wmv"]
#skip ^^^. accept all files. if ffmpeg has a demuxer, read will succeed.

#cli options  
#--help print this block
#-cfg config_file
#-c convert
#-i info
#-f input of single file
#-d input of directory tree contents
#-p process pool size (require -c)
#-t target dir (require -c)
#-cpu cpu transcode (require -c)
#-gpu gpu transcode (require -c)
#-gpu_dev [0,1,2,...] (require -gpu)
#-audio_fmt audio format as understood by ffmpeg (aac)
#-video_fmt video format as understood by ffmpeg (h264)


#defaults
#-p 1
#-cpu
#-t ./


# dlnaify.rb (-c or -i) (-f or -d) source [-t target_dir] 
# dlnaify.rb -c -d /opt/derp => convert everything in /opt/derp with default options
# dlnaify.rb -c -f /opt/derp/derp2.mkv => convert derp2.mkv
# dlnaify.rb -c -d /opt/derp -p 6 => 6 at a time
# dlnaify.rb -c -d /opt/derp -p 6 -t /opt/target => 6 at a time, using root dir 'target'
# dlnaify.rb -i -f /opt/derp/derp2.mkv => display av info on target file
# dlnaify.rb -i -d /opt/derp/ => display av info on target dir files

convert = false
source_isdir = false
target = nil

num_threads = 1

#confdir defaults to ./conf

#convert or info?
convert = true if ARGV.index("-c") != nil

#directory or single file?
source_isdir = true if ARGV.index("-d") != nil

#use multiple threads?
if(convert)

  thread_flag = ARGV.index("-p")
  
  if(thread_flag != nil)
    num_threads = ARGV[thread_flag + 1].to_i
  end
    
end

target_flag = ARGV.index("-t")

if(target_flag != nil)
  target = ARGV[target_flag + 1]
end

#enforce relative to binary
#default at ./conf/
config_file = nil
config_flag = ARGV.index("-cfg")

if(config_flag != nil)
  config_file = ARGV[config_flag + 1]
end



config = Config.new(config_file)

#set cli options

#build the converter here. we will still need it for probes
#TODO: no we don't/shouldn't. config should be sufficent
conv = Converter.new(config, num_threads)

if !convert
  
  if source_isdir
    # run find on dir
    dir = ARGV[3]
    
    abort("Source dir #{dir} does not exist") unless dir and Dir.exists?(dir)
    
    Find.find(dir) { |file| 
      if(File.ftype(file) == "file" && FILE_FMTS[File.extname(file)] )  
        results = conv.probe_file(file)
        
        puts "==========================="
        puts "file: " << file
        
        results["video"].each do |stream, index|
          puts "video#{index}: " << stream.to_s
        end
        
        results["audio"].each do |stream, index|
          puts "audio#{index}: " << stream.to_s
        end
        puts "==========================="
      end  
    }
    
  else
    #get stream info for file
    file = ARGV[2]
    abort("Source file does not exist") unless file and File.exists?(file)
    
    results = conv.probe_file(file)
    
    puts "==========================="
    puts "file: " << file
    results["video"].each_with_index do |stream, index|
      puts "video#{index}: " << stream.to_s
    end
    
    results["audio"].each_with_index do |stream, index|
      puts "audio#{index}: " << stream.to_s
    end
    puts "==========================="
    
  end
  
else
  
  #conversion
  #convert file   
  if source_isdir
    # run find on dir
    dir = ARGV[4]

    abort("Source dir #{dir} does not exist") unless dir and Dir.exists?(dir)

    #add mimetype check
    
    Find.find(dir) { |file| 
      #TODO: remove mkv
      if(File.ftype(file) == "file" && File.extname(file) == ".mkv")         
        conv.add_file(file, target)
      end  
    }
  else
    #get stream info for file
    file = ARGV[2]
    abort("Source file does not exist") unless File.exists?(file)

    conv.add_file(file, target)
  end
  
  conv.run()
  
  
  #report any conversion result
  
  
end



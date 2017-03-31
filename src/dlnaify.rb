require 'find'
require_relative 'Converter.rb'

####################################################

FILE_FMTS = ["mkv", "mp4", "avi", "mpg", "m4v", "wmv"]
  

#wrap avconv or ffmpeg
#avconv for now

# dlnaify.rb (-c or -i) (-f or -d) source [-t target_dir] 
# dlnaify.rb -c -d /opt/derp => convert everything in /opt/derp with default options
# dlnaify.rb -c -f /opt/derp/derp2.mkv => convert derp2.mkv
# dlnaify.rb -c -d /opt/derp -p 6 => 6 at a time
# dlnaify.rb -c -d /opt/derp -p 6 -t /opt/target => 6 at a time, using root dir 'target'
# dlnaify.rb -i -f /opt/derp/derp2.mkv => display av info on target file
# dlnaify.rb -i -d /opt/derp/ => display av info on target dir files

#find avconv

convert = false
source_isdir = false
target = nil

num_threads = 1

#convert or info?
convert = true if ARGV.index("-c") != nil

#directory or single file?
source_isdir = true if ARGV.index("-d") != nil

#use multiple threads?
if(convert)

  thread_param = ARGV.index("-p")
  
  if(thread_param != nil)
    num_threads = ARGV[thread_param + 1].to_i
  end
    
end

target_param = ARGV.index("-t")

if(target_param != nil)
  target = ARGV[target_param + 1]
end

conv = Converter.new(num_threads)

#abort("Both convert and info options specified. Choose one.") if convert  

if !convert
  
  if source_isdir
    # run find on dir
    dir = ARGV[2]
    
    abort("Source dir does not exist") unless Dir.exists?(dir)
    
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
    abort("Source file does not exist") unless File.exists?(file)
    
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
    dir = ARGV[2]

    abort("Source dir does not exist") unless Dir.exists?(dir)

    #add mimetype check
    
    Find.find(dir) { |file| 
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



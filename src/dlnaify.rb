require 'find'
require_relative 'convert/Converter.rb'

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

######################
#cli args

#confdir defaults to ./conf

#########
#help - show capabilities of dlnaify/ffmpeg install
help = (ARGV.index("-help") != nil) || (ARGV.index("-h") != nil) || (ARGV.index("--help") != nil)

#print help info and exit
#sample uses
if(help)
  
  puts ("I'm helping!")
  exit
end
#########
#info - show capabilities of dlnaify/ffmpeg install
#considers -cfg option
info = ARGV.index("-info") != nil

#########
#convert or probe?
convert = true if ARGV.index("-c") != nil

#########
#directory or single file?
source_isdir = true if ARGV.index("-d") != nil

#########
#use multiple processes?
if(convert)

  thread_flag = ARGV.index("-p")
  
  if(thread_flag != nil)
    num_threads = ARGV[thread_flag + 1].to_i
  end
    
end

##########
#target 

target_flag = ARGV.index("-t")

if(target_flag != nil)
  target = ARGV[target_flag + 1]
end

##########
#config file

#enforce relative to binary
#default at ./conf/
config_file = nil
config_flag = ARGV.index("-cfg")

if(config_flag != nil)
  config_file = ARGV[config_flag + 1]
end

##########
#cpu or gpu transcode
#cpu is default

gpu_transcode = ARGV.index("-gpu") != nil

##########
#gpu options

gpu_use_devices = nil
gpu_devices = nil

if(gpu_transcode)
  gpu_use_devices = ARGV.index("-gpu_dev") != nil
  
  #0,1,3 - comma-separated no spaces
  #default is all devices
  if(gpu_use_devices)
    gpu_devices = ARGV[ARGV.index("-gpu_dev") + 1]
  end
end

##########
#video format override

video_format_override = nil
if(ARGV.index("-vf"))
  video_format_override = ARGV[ARGV.index("-vf") + 1]
end

##########
#audio format override

audio_format_override = nil
if(ARGV.index("-af"))
  audio_format_override = ARGV[ARGV.index("-af") + 1]
end

##########
#volume normalization

vol_norm = nil
if(ARGV.index("-vol"))
  vol_norm = ARGV[ARGV.index("-vol") + 1]
end

#################################

#TODO: switch to config factory
config = Config.new(config_file)

#set cli options

if(info)
  
  puts(config.dump_config)
  
  exit
end

#format overrides ie h264 or hevc. it's up to the config to resolve codecs from formats
config.set_target_video_format(video_format_override) if video_format_override
config.set_target_audio_format(audio_format_override) if audio_format_override

if(gpu_transcode)
  
  config.use_gpu_for_transcode(true)
  
  #devices
  if(gpu_use_devices)
    
    #TODO: implement
    #config.set_gpu_devices(gpu_devices.split(/\,/))
  end
  
  #TODO: implement if we want to allow this from the cli
  #hw accel?
  #config.set_gpu_hw_accel(whatever)
end

#TODO: implement
#volume normalization
#config.set_volume_normalization(vol_norm) if vol_norm

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
    
    start_time = Time.now.to_f
    
    Find.find(dir) { |file| 
      if(File.ftype(file) == "file" )         
        conv.add_file(file, target)
      end  
    }
    
    end_time = Time.now.to_f

    MyLogger.instance.info("dlnaify", "Loading files took #{(end_time-start_time)} s")
    
  else
    #get stream info for file
    file = ARGV[2]
    abort("Source file does not exist") unless File.exists?(file)

    conv.add_file(file, target)
  end
  
  conv.run()
  
  
  #report any conversion result
  
  
end



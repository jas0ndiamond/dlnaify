require 'test/unit'
require_relative "../../src/convert/Converter.rb"

#process and transcode our testfile
#cleanup results

class ConverterTest < Test::Unit::TestCase 
  
  attr_accessor :instance

  
  #find testfiles in resources dir
  #expected framecounts
  #expected transcode results
  #syscalls don't return failures
  
  #sample source file in test/resources
  #why test converting to many formats?
  #maybe have tests for conversion but run those based on supported output formats in config file 
    
  def setup
    puts "running setup ConverterTestLong"

#    ffmpeg -i resources/SampleVideo_640x360_10mb.mkv -c:v libx265 -c:a -f resources/SampleVideo_640x360_10mb_hevc.mkv 
#    ffmpeg -i resources/SampleVideo_640x360_10mb.mkv -c:v libx265 -c:a copy -f resources/SampleVideo_640x360_10mb_hevc.mkv 
#    ffmpeg -i resources/SampleVideo_640x360_10mb.mkv -c:v libx265 -c:a copy resources/SampleVideo_640x360_10mb_hevc.mkv 
#    ffmpeg -i resources/SampleVideo_640x360_10mb.mkv -c:v libx265 -c:a ac3 resources/SampleVideo_640x360_10mb_hevc.mkv 
#    ffmpeg -i resources/SampleVideo_640x360_10mb.mkv -c:v libx265 -c:a ac3 resources/SampleVideo_640x360_10mb_hevc_ac3.mkv 
#    ffmpeg -i resources/SampleVideo_640x360_10mb.mkv -c:v mjpeg -c:a libvorbis resources/SampleVideo_640x360_10mb_mjpeg_vorbis.mkv 

  end

  def test_it_does_something_useful
    assert true
  end
  
  def teardown
    puts "teardown"
  end
end
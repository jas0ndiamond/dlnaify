require 'test/unit'
require_relative "../src/Converter.rb"

#basic converter operations. dry runs on transcodes.
#look at resultant syscall

class ConverterTest < Test::Unit::TestCase 
  
  attr_accessor :instance
  
  def setup
    puts "running setup ConverterTest"
    #@instance = MediaFile.new("", "")
  end

  def test_it_does_something_useful
    assert true
  end
  
  def teardown
    puts "teardown"
  end
end
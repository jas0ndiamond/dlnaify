require 'test/unit'
require_relative "../src/Converter.rb"

#basic converter operations.

class ConverterTest < Test::Unit::TestCase 
  
  attr_accessor :instance
  
  def setup
    puts "running setup ConverterTest"
    #@instance = MediaFile.new("", "")
  end

  def test_it_does_something_useful
    assert true
  end
  
  def test_conversion_with_no_files
  end
  
  def teardown
    puts "teardown"
  end
end
require 'test/unit'

# encoding: utf-8

require_relative '../../src/util/MyFileUtils.rb'

class MyFileUtilsTest < Test::Unit::TestCase 
  
  attr_accessor :tmp_dir 
  
  def setup
    #create the test files on the file system
        
    #get the test dir, which this file should be in
    test_dir = File.expand_path(File.dirname(__FILE__))
    
    #setup tmpdir in resources
    @tmp_dir = File.expand_path("#{test_dir}/../resources/tmp")
    Dir.mkdir(@tmp_dir)
    raise RuntimeError.new("Couldn't create tmp dir #{@tmp_dir} for testing") unless 
      File.exists?(@tmp_dir)
  end
  
  def teardown
    
    #clear out dir
    Dir.foreach(@tmp_dir) do |f|
      fn = File.join(@tmp_dir, f)
      File.delete(fn) if f != '.' && f != '..'
    end
    
    Dir.rmdir(@tmp_dir)
    raise RuntimeError.new("Could not remove tmp dir #{@tmp_dir}") unless
       !File.exists?(@tmp_dir)
  end
  
  def test_escape_simple
    testfile = "#{@tmp_dir}/simplefile.txt"
    
    test_escaping(testfile, testfile)
  end

  def test_escape_apostrophe
    testfile = "#{@tmp_dir}/apostrophe'file.txt"
    
    test_escaping(testfile, "#{@tmp_dir}/apostrophe\'file.txt")
  end  
  
  def test_escape_backtick
    testfile = "#{@tmp_dir}/backtick`file.txt"
    
    test_escaping(testfile, "#{@tmp_dir}/backtick\`file.txt")
  end  
  
  def test_escape_parens
    testfile = "#{@tmp_dir}/parens_(derp)_file.txt"
    
    test_escaping(testfile, "#{@tmp_dir}/parens_\(derp\)_file.txt")
  end  
  
  def test_escape_braces
    testfile = "#{@tmp_dir}/braces_{derp}_file.txt"
    
    test_escaping(testfile, "#{@tmp_dir}/braces_\{derp\}_file.txt")
  end  
  
  def test_escape_brax
    testfile = "#{@tmp_dir}/brax_[derp]_file.txt"
    
    test_escaping(testfile,  "#{@tmp_dir}/brax_\[derp\]_file.txt")
  end  
  
  def test_escape_angle_brax
    testfile = "#{@tmp_dir}/brax_<derp>_file.txt"
    
    test_escaping(testfile,  "#{@tmp_dir}/brax_\<derp\>_file.txt")
  end  
  
  def test_escape_pipe
    testfile = "#{@tmp_dir}/pipe_|derp|_file.txt"
        
    test_escaping(testfile, "#{@tmp_dir}/pipe_\|derp\|_file.txt")
  end  
  
  def test_escape_quote
    testfile = "#{@tmp_dir}" + '/quote"file.txt'
    
    test_escaping(testfile, "#{@tmp_dir}/quote\"file.txt")
  end  
  
  def test_escape_colon
    testfile = "#{@tmp_dir}" + '/colon:file.txt'
    
    test_escaping(testfile, "#{@tmp_dir}/colon\:file.txt")
  end  
  
  def test_escape_semicolon
    testfile = "#{@tmp_dir}" + '/semicolon;file.txt'
    
    test_escaping(testfile, "#{@tmp_dir}/semicolon\;file.txt")
  end  
  
  def test_escape_bang
    testfile = "#{@tmp_dir}" + '/bang!file.txt'
    
    test_escaping(testfile, "#{@tmp_dir}/bang\!file.txt")
  end  
  
  def test_escape_at
    testfile = "#{@tmp_dir}" + '/at@file.txt'
      
    test_escaping(testfile, "#{@tmp_dir}/at\@file.txt")
  end  
  
  def test_escape_othorpe
    testfile = "#{@tmp_dir}" + '/othorpe#file.txt'
    
    test_escaping(testfile, "#{@tmp_dir}/othorpe\#file.txt")
  end  
  
  def test_escape_dollar
    testfile = "#{@tmp_dir}" + '/dollar$file.txt'
    
    test_escaping(testfile, "#{@tmp_dir}/dollar\$file.txt")
  end  
  
  def test_escape_percent
    testfile = "#{@tmp_dir}" + '/percent%file.txt'
    
    test_escaping(testfile, "#{@tmp_dir}/percent\%file.txt")
  end  

  def test_escape_carat
    testfile = "#{@tmp_dir}" + '/carat^file.txt'
    
    test_escaping(testfile, "#{@tmp_dir}/carat\^file.txt")
  end  
    
  def test_escape_amper
    testfile = "#{@tmp_dir}" + '/amper&file.txt'
    
    test_escaping(testfile, "#{@tmp_dir}/amper\&file.txt")
  end  
  
  def test_escape_asterisk
    testfile = "#{@tmp_dir}" + '/asterisk*file.txt'
    
    test_escaping(testfile, "#{@tmp_dir}/asterisk\*file.txt")
  end  
    
  def test_escape_backslash
    testfile = "#{@tmp_dir}" + '/backslash\\file.txt'

    test_escaping(testfile, "#{@tmp_dir}/backslash\\file.txt")
  end  
  
  def test_escape_space
    testfile = "#{@tmp_dir}" + '/space file.txt'

    test_escaping(testfile, "#{@tmp_dir}/space\ file.txt")
  end  
  
  def test_escape_qmark
    testfile = "#{@tmp_dir}" + '/qmark?file.txt'

    test_escaping(testfile, "#{@tmp_dir}/qmark\?file.txt")
  end
  
  def test_escape_shitshow
    testfile = "#{@tmp_dir}/shitshow_'({[|derp|]})`````_file.txt"
        
    test_escaping(testfile, "#{@tmp_dir}/shitshow_\'\(\{\[\|derp\|\]\}\)\`\`\`\`\`_file.txt")
  end  
  
  def test_escape_shitshow2
    testfile = "#{@tmp_dir}/" << 'shitshow2_!@#$%^&*derp!@#$%^&*_file.txt'
        
    test_escaping(testfile, "#{@tmp_dir}/" << "shitshow2_\!\@\#\$\%\^\&\*derp\!\@\#\$\%\^\&\*_file.txt")
  end  
  
  def test_escape_shitshow3
    testfile = "#{@tmp_dir}/" << 'shitshow3\\\\derp\\\\file.txt'
        
    test_escaping(testfile, "#{@tmp_dir}/" << "shitshow3\\\\derp\\\\file.txt")
  end  
  
  #########
  
  def test_escaping(testfile, expected)
            
    begin      
      #create file with (optionally) weird chars with File, which will not need escaping
      handle = File.new(testfile, "w")
      
      #check file existence
      assert_true( File.exists?(testfile) )
  
      #get clean/escaped version
      cleanfile = MyFileUtils.instance.escape_path(testfile)
      
      #puts "\ncleanfile: [#{cleanfile}]\n"
      
      #use clean file in system call
      assert_equal( expected, `ls #{cleanfile}`.chomp)
    ensure
      File.unlink(testfile) unless !File.exists?(testfile)
      handle.close unless !handle
    end
    
  end
  
end
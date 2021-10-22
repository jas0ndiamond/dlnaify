require 'test/unit'
require 'logger'

require_relative "../src/MediaFile.rb"

class MediaFileTest < Test::Unit::TestCase 
  
  attr_accessor :tmp_dir 
  
  def setup
    #puts "running setup MediaFileTest"
    #@instance = MediaFile.new("", "")
    
    #get the test dir, which this file should be in
    test_dir = File.expand_path(File.dirname(__FILE__))
    
    #setup tmpdir in resources
    @tmp_dir = File.expand_path("#{test_dir}/resources/tmp")
    Dir.mkdir(@tmp_dir)
    raise RuntimeError.new("Couldn't create tmp dir #{@tmp_dir} for testing") unless 
      File.exists?(@tmp_dir)
      
    #puts "Created tmpdir #{@tmp_dir}"
  end
  
  def test_nil_source_path
    assert_raise Errno::ENOENT do
      MediaFile.new( nil, "/dev/null" )
    end
  end
  
  def test_empty_source_path
    assert_raise Errno::ENOENT do
      MediaFile.new( "", "/dev/null" )
    end
  end
  
  def test_missing_source_path 
    assert_raise Errno::ENOENT do
      MediaFile.new( "/oh/my/goodness/its/all/total/nonsense/a1b2c3d4.mkv", "/dev/null" )
    end
  end
  
  def test_empty_source_contents
    assert_raise Errno::ENOENT do
      MediaFile.new( "", "/dev/null" )
    end
  end
  
  def test_nonsense_source_contents
    assert_nothing_thrown do
      testfile = "#{@tmp_dir}/testfile.mkv"
      
      begin
        handle = File.new(testfile, "w")
      
        raise RuntimeError.new("Could not create testfile") unless File.exists?(testfile)
      
      
        MediaFile.new( testfile, "/dev/null" )
      ensure
        File.unlink(testfile) unless !File.exists?(testfile)
        handle.close unless !handle
      end
    end
  end
  
  def test_available_source_file
    
    assert_nothing_thrown do
      testfile = "#{@tmp_dir}/testfile.mkv"
      
      begin
        handle = File.new(testfile, "w")

        raise RuntimeError.new("Could not create testfile") unless File.exists?(testfile)

        mediaFile = MediaFile.new( testfile, "/dev/null" )

        assert mediaFile.path.end_with?("#{@tmp_dir}/testfile.mkv")
        assert_equal( mediaFile.dest, "/dev/null")

      ensure
        File.unlink(testfile) unless !File.exists?(testfile)
        handle.close unless !handle
      end
    end
  end
  
  def test_source_file_with_backticks
    #backticks
    
    assert_nothing_thrown do
      testfile = "#{@tmp_dir}/test`file.mkv"
      
      begin
        handle = File.new(testfile, "w")

        raise RuntimeError.new("Could not create testfile") unless File.exists?(testfile)

        mediaFile = MediaFile.new( testfile, @tmp_dir )

        #assert mediaFile.path.end_with?("/resources/testfile.mkv")
        #assert mediaFile.dest == "/dev/null"
        
        #check source
        assert_true( File.exists?(mediaFile.path))
        
        #check dest
        assert_equal( "#{@tmp_dir}/testfile.mkv", mediaFile.get_safe_dest_path) 
        assert_equal( @tmp_dir, mediaFile.dest)

      ensure
        File.unlink(testfile) unless !File.exists?(testfile)
        handle.close unless !handle
      end
      
      #mediaFile = MediaFile.new(testfile, "/dev/null")
      #puts "\n" + mediaFile.get_safe_dest_path(testfile)
      #assert mediaFile.get_safe_dest_path == "./resources/testfile.mkv"
    end
    
    #apostrophes
    #quotes
    #spaces
  end
  
  def test_missing_dest
    assert_raise Errno::ENOENT do
      testfile = "#{@tmp_dir}/testfile.mkv"
      
      begin
        handle = File.new(testfile, "w")

        MediaFile.new( testfile, "/absolute/nothing/noway/a1b2c3/" )
      ensure
        File.unlink(testfile) unless !File.exists?(testfile)
        handle.close unless !handle
      end
    end
  end
  
  def test_nil_dest
    assert_raise Errno::ENOENT do
      testfile = "#{@tmp_dir}/testfile.mkv"
      begin
        handle = File.new(testfile, "w")

        MediaFile.new( testfile, nil )
      
     ensure
      File.unlink(testfile) unless !File.exists?(testfile)
      handle.close unless !handle
     end    
    end
  end
  
  def test_unwriteable_dest
    assert_raise Errno::ENOENT do
      testfile = "#{@tmp_dir}/testfile.mkv"
      begin
        handle = File.new(testfile, "w")

        MediaFile.new( testfile, "/derpfile" )
      
      ensure
        File.unlink(testfile) unless !File.exists?(testfile)
        handle.close unless !handle
      end
    end
  end
  
  def test_source_with_leading_brax
    assert_nothing_thrown do
      testfile = "#{@tmp_dir}/[fart]testfile.mkv"
      
      begin
        handle = File.new(testfile, "w")

        raise RuntimeError.new("Could not create testfile") unless File.exists?(testfile)

        mediaFile = MediaFile.new( testfile, @tmp_dir )
        #puts mediaFile.path
        #puts mediaFile.dest
        
        #check source
        assert_true( File.exists?(mediaFile.path))
        
        #check dest
        assert_equal( "#{@tmp_dir}/testfile.mkv", mediaFile.get_safe_dest_path )
        assert_equal( @tmp_dir, mediaFile.dest)

      ensure
        File.unlink(testfile) unless !File.exists?(testfile)
        handle.close unless !handle
      end
    end
  end
  
  def test_source_with_leading_dot
    assert_nothing_thrown do
      testfile = "#{@tmp_dir}/.testfile.mkv"
      
      begin
        handle = File.new(testfile, "w")

        raise RuntimeError.new("Could not create testfile") unless File.exists?(testfile)

        mediaFile = MediaFile.new( testfile, @tmp_dir )
        #puts mediaFile.path
        #puts mediaFile.dest
        
        #check source
        assert_true( File.exists?(mediaFile.path))
        
        #check dest
        assert_equal("#{@tmp_dir}/testfile.mkv", mediaFile.get_safe_dest_path )
        assert_equal(@tmp_dir, mediaFile.dest )

      ensure
        File.unlink(testfile) unless !File.exists?(testfile)
        handle.close unless !handle
      end
    end
  end
  
  def test_source_with_apostrophe
    assert_nothing_thrown do
      testfile = "#{@tmp_dir}/test'file.mkv"
      
      begin
        handle = File.new(testfile, "w")

        raise RuntimeError.new("Could not create testfile") unless File.exists?(testfile)

        mediaFile = MediaFile.new( testfile, @tmp_dir )
        #puts mediaFile.path
        #puts mediaFile.dest
        
        #check source
        assert_true( File.exists?(mediaFile.path))
        
        #check dest
        assert_equal("#{@tmp_dir}/testfile.mkv", mediaFile.get_safe_dest_path )
        assert_equal(@tmp_dir, mediaFile.dest )

      ensure
        File.unlink(testfile) unless !File.exists?(testfile)
        handle.close unless !handle
      end
    end
  end
  
  def test_source_with_apostrophes
    assert_nothing_thrown do
      testfile = "#{@tmp_dir}/test'''''''file.mkv"
      
      begin
        handle = File.new(testfile, "w")

        raise RuntimeError.new("Could not create testfile") unless File.exists?(testfile)

        mediaFile = MediaFile.new( testfile, @tmp_dir )
        #puts mediaFile.path
        #puts mediaFile.dest
        
        #check source
        assert_true( File.exists?(mediaFile.path))
        
        #check dest
        assert_equal("#{@tmp_dir}/testfile.mkv", mediaFile.get_safe_dest_path )
        assert_equal(@tmp_dir, mediaFile.dest )

      ensure
        File.unlink(testfile) unless !File.exists?(testfile)
        handle.close unless !handle
      end
    end
  end
  
  def test_source_with_quotes
    assert_nothing_thrown do
      testfile = "#{@tmp_dir}" + '/test"""""file.mkv'
      
      begin
        handle = File.new(testfile, "w")

        raise RuntimeError.new("Could not create testfile") unless File.exists?(testfile)

        mediaFile = MediaFile.new( testfile, @tmp_dir )
        #puts mediaFile.path
        #puts mediaFile.dest
        
        #check source
        assert_true( File.exists?(mediaFile.path))
        
        #check dest
        assert_equal("#{@tmp_dir}/testfile.mkv", mediaFile.get_safe_dest_path )
        assert_equal(@tmp_dir, mediaFile.dest )

      ensure
        File.unlink(testfile) unless !File.exists?(testfile)
        handle.close unless !handle
      end
    end
  end
  
  def test_source_with_semicolons
    assert_nothing_thrown do
      testfile = "#{@tmp_dir}" + '/test;;;;;file.mkv'
      
      begin
        handle = File.new(testfile, "w")

        raise RuntimeError.new("Could not create testfile") unless File.exists?(testfile)

        mediaFile = MediaFile.new( testfile, @tmp_dir )
        #puts mediaFile.path
        #puts mediaFile.dest
        
        #check source
        assert_true( File.exists?(mediaFile.path))
        
        #check dest
        assert_equal("#{@tmp_dir}/testfile.mkv", mediaFile.get_safe_dest_path )
        assert_equal(@tmp_dir, mediaFile.dest )

      ensure
        File.unlink(testfile) unless !File.exists?(testfile)
        handle.close unless !handle
      end
    end
  end
  
  def test_source_with_leading_parens
    assert_nothing_thrown do
      testfile = "#{@tmp_dir}" + '/(fart)testfile.mkv'
      
      begin
        handle = File.new(testfile, "w")

        raise RuntimeError.new("Could not create testfile") unless File.exists?(testfile)

        mediaFile = MediaFile.new( testfile, @tmp_dir )
        #puts mediaFile.path
        #puts mediaFile.dest
        
        #check source
        assert_true( File.exists?(mediaFile.path))
        
        #check dest
        assert_equal("#{@tmp_dir}/testfile.mkv", mediaFile.get_safe_dest_path )
        assert_equal(@tmp_dir, mediaFile.dest )

      ensure
        File.unlink(testfile) unless !File.exists?(testfile)
        handle.close unless !handle
      end
    end
  end
  
  def test_source_with_lots_of_problems
    assert_nothing_thrown do
      testfile = "#{@tmp_dir}/(fart).test';''''';;;'file.mkv"
      
      begin
        handle = File.new(testfile, "w")

        raise RuntimeError.new("Could not create testfile") unless File.exists?(testfile)

        mediaFile = MediaFile.new( testfile, @tmp_dir )
        #puts mediaFile.path
        #puts mediaFile.dest
        
        #check source
        assert_true( File.exists?(mediaFile.path))
        
        #check dest
        assert_equal("#{@tmp_dir}/testfile.mkv", mediaFile.get_safe_dest_path )
        assert_equal(@tmp_dir, mediaFile.dest )

      ensure
        File.unlink(testfile) unless !File.exists?(testfile)
        handle.close unless !handle
      end
    end
  end
  
  def teardown
    #puts "teardown"
    #puts "Deleting tmpdir #{@tmp_dir}"

    Dir.rmdir(@tmp_dir)
    raise RuntimeError.new("Could not remove tmp dir #{@tmp_dir}") unless
       !File.exists?(@tmp_dir)
  end
end
# encoding: utf-8

class MyFileUtils

  def initialize
    
  end
  
  @@instance = MyFileUtils.new

  def self.instance
    return @@instance
  end
  
  def sanitize(filename)
    # Remove any character that aren't 0-9, A-Z, or a-z, or space
    return filename.gsub(/[^0-9A-Za-z\ ]/, '_')
  end
  
  def escape_path(path)
    
    #turn a path into its escaped equivalent
    
    #puts "Path #{path}"
    
    #backslash
    result = path.gsub("\\", %q(\\\\\\\\) )   
    
    #apostrophes
    result.gsub!("'", %q(\\\') )
    
    #quotes
    result.gsub!('"', %q(\\\") )    
        
    #backticks
    result.gsub!('`', %q(\\\`) )  
    
    #parens
    result.gsub!('(', %q(\\\() )  
    result.gsub!(')', %q(\\\)) )
      
    #braces
    result.gsub!('{', %q(\\\{) )  
    result.gsub!('}', %q(\\\}) )
    
    #brackets
    result.gsub!('[', %q(\\\[) )  
    result.gsub!(']', %q(\\\]) )
    
    #pipe
    result.gsub!('|', %q(\\\|) )   
    
 
    
    #colons
    result.gsub!(':', %q(\\\:) )   
    result.gsub!(';', %q(\\\;) )   

    #other top row symbols
    result.gsub!('!', %q(\\\!) )
    result.gsub!('@', %q(\\\@) )
    result.gsub!('#', %q(\\\#) )
    result.gsub!('$', %q(\\\$) )
    result.gsub!('%', %q(\\\%) )
    result.gsub!('^', %q(\\\^) )
    result.gsub!('&', %q(\\\&) )
    result.gsub!('*', %q(\\\*) )
    
    #qmark
    result.gsub!('?', %q(\\\?) )
    
    #space
    result.gsub!(" ", %q(\\\ ) )
    
    #angle brax
    result.gsub!(">", %q(\\\>) )
    result.gsub!("<", %q(\\\<) )
    
    return result
  end
  
  private_class_method :new
  
end

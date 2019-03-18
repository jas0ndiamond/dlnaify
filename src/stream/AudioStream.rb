class AudioStream
  attr_accessor :index, :identifier, :lang, :format
  
  def initialize(identifier, index, lang, format)
    @identifier = identifier
    @index = index
    @lang = lang
    @format = format
  end
  
  def to_s
    return "identifier #{@identifier}, index: #{@index}, lang:#{@lang}, format: #{@format}"
  end
  
end
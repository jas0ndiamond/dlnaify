class VideoStream
  attr_accessor :identifier, :index, :format, :pixel_format, :frame_count
  
  def initialize(identifier, index, format, pixel_format, frame_count=0)
    @identifier = identifier
    @index = index
    @format = format
    @pixel_format = pixel_format
    @frame_count = frame_count
  end
  
  def to_s
    return "identifier: #{identifier}, index: #{@index}, format:#{@format}, pixel_format: #{@pixel_format}, frame_count: #{@frame_count}"
  end
  
end
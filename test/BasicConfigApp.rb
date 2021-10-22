require_relative "../src/Config.rb"

conf = Config.new("../conf/dlnaify.conf")

puts conf.dump_config
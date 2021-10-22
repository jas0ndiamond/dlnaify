require_relative "../../src/config/ProbeConfig.rb"

conf = ProbeConfig.new("../conf/dlnaify.conf")

puts conf.dump_config
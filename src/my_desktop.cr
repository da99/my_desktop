
require "da"
require "da/Redis"
require "redis"


Dir.cd("/apps/my_desktop")
r = DA.new_redis("redis.conf")
r.subscribe("wm_info") do |on|
  on.message do |channel, message|
    puts "#{channel} #{message}"
  end
end

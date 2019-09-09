
require "da"
require "da/Redis"
require "da/Watch"
require "da/Window"
require "redis"

module MY_DESKTOP
  REDIS_CONF = "/apps/my_#{`hostname`.strip}/redis.conf"

  extend self
  REDIS_POOL = DA.new_redis(REDIS_CONF)

  def redis
    REDIS_POOL
  end # def

  def publish_bspwm
    bspc = DA::Watch.new("bspc subscribe all")
    while bspc.readable?
      sleep 0.1
      raw = bspc.read_line
      if raw
        redis.publish "bspwm", raw
      end
    end # while
  end # def

  def top_hud
    window_focus_id = ""
    redis.subscribe("bspwm") { |on|
      on.message { |channel, message|
        case
        when channel == "bspwm" && message[/^node_focus/]?
          raw_id = message.split.last
          if raw_id
            window_focus_id = DA::Window.clean_id(raw_id)
          end
          puts "New window focus: #{window_focus_id}"
        end # case
      }
    } # subscribe
  end # def

end # === module


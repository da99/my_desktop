
require "da"
require "da/Watch"
require "da/Redis"
require "da/Watch"
require "da/Window"
require "da/Volume"
require "redis"

module MY_DESKTOP

  extend self

  REDIS_POOL = DA.new_redis("/apps/my_#{`hostname`.strip}/redis.conf")

  def redis
    REDIS_POOL
  end # def

  def publish_bspwm
    bspc = DA::Watch.new("bspc subscribe all")
    while bspc.readable?
      sleep 0.1
      l = bspc.read_line
      if l
        redis.publish("bspwm", l.strip)
      end
    end # while
  end # def


  def publish_udev
    udevadm = DA::Watch.new("udevadm monitor")
    while udevadm.readable?
      sleep 0.1
      line = udevadm.read_line
      if line
        redis.publish("udev", line.strip)
      end
    end # while
  end # def

  def publish_pulseaudio
    pa = DA::Watch.new("pactl subscribe")
    while pa.readable?
      sleep 0.1
      line = pa.read_line
      if line
        redis.publish("pulseaudio", line.strip)
      end
    end # while
  end # def

  def window_title
    xtitle  = DA::Watch.new("xtitle -s")
    while xtitle.readable?
      sleep 0.1
      window_title = xtitle.read_line
      redis.publish("window_title", window_title || "[no window title]")
    end
  end # def

  def publish_volume
    redis.subscribe("pulseaudio") do |on|
      on.message { |channel, message|
        if message[/Event 'remove'/]?
          vol = DA.volume_master
          redis.publish("volume.master", vol.num.to_s)
          redis.publish("volume.master.status", vol.status)
        end
      }
    end
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




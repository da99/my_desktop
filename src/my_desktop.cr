
require "da"
require "da/Watch"
require "da/Redis"
require "redis"

module MY_DESKTOP

  extend self

  REDIS = DA.new_redis("/apps/my_desktop/redis.conf")

  def redis
    REDIS
  end

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

end # === module



require "../src/my_desktop"

full_cmd = ARGV.map(&.strip).join(' ')

case
when full_cmd == "publish_bspwm"
  # === {{CMD}} publish_bspwm
  MY_DESKTOP.publish_bspwm

when full_cmd == "publish_udev"
  # === {{CMD}} publish_udev
  MY_DESKTOP.publish_udev

when full_cmd == "publish_pulseaudio"
  # === {{CMD}} publish_pulseaudio
  MY_DESKTOP.publish_pulseaudio

when full_cmd == "publish_volume"
  # === {{CMD}} publish_volume
  MY_DESKTOP.publish_volume

when full_cmd[/^runit /]?
  # === {{CMD}} runit name_of_service
  # Create a runit service in sv/ dir.
  name = ARGV[1].strip
  Dir.cd "/apps/my_desktop"
  `mkdir -p sv/#{name}/log`
  File.write("sv/#{name}/run", <<-EOF)
  #!/bin/sh

  exec 2>&1

  echo "=== Starting sv/#{name}: $(date)"

  set -x
  cd /apps/my_desktop
  exec bin/my_desktop #{name}
  EOF
  File.write("sv/#{name}/log/run", <<-EOF)
  #!/bin/sh
  #
  #
  # exec logger -p daemon.notice -t www_paradise
  set -u -e
  sv_log_dir=/progs/logs/my_desktop_#{name}
  mkdir -p        $sv_log_dir
  exec svlogd -tt $sv_log_dir
  EOF
  `chmod +x sv/#{name}/run`
  `chmod +x sv/#{name}/log/run`
  Process.exec "tree", ["sv/#{name}"]
else
  DA.orange! "!!! Unknown command: {{#{full_cmd}}}"
  Process.exit 1

end # case

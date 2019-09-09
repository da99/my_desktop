
require "../src/my_desktop"

full_cmd = ARGV.map(&.strip).join(' ')
{% for name in "top_hud publish_bspwm".split %}
  if full_cmd == {{name}}
    MY_DESKTOP.{{name.id}}
    Process.exit 0
  end
{% end %}

DA.red! "=== {{Unknown command}}: #{full_cmd}"
Process.exit 1

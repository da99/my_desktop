
require "json"

module I3

  def self.outside_windows
    group = Deque(Window).new
    window = I3.current_window

    if window
      workspace = window.workspace
      wg = workspace.geometry
      workspace.floating_windows.each { |w|
        g = w.geometry
        if g.y < 1 || g.x < 1 || g.x > wg.width || g.y > wg.h
          group << w
        end
      }
    end

    group
  end # def

  class Geometry
    JSON.mapping(
      x: Int32,
      y: Int32,
      width: Int32,
      height: Int32
    )

    def w
      width
    end

    def h
      height
    end
  end # === class

  class Window_Properties
    JSON.mapping(
      class: String,
      instance: String,
      title: String,
      transient_for: {type: Int32, nilable: true}
    )
  end # === class

  class Node
    JSON.mapping(
      id:                   Int32,
      name:                 {type: String, nilable: true},
      type:                 String,
      border:               String,
      current_border_width: Int32,
      layout:               String,
      percent:              {type: Float64, nilable: true},
      rect:                 Geometry,
      window_rect:          Geometry,
      deco_rect:            Geometry,
      geometry:             Geometry,
      window:               {type: Int32, nilable: true},
      window_properties:    {type: Window_Properties, nilable: true},
      urgent:               Bool,
      focused:              Bool,
      focus:                Array(Int32),
      nodes:                Array(Node),
      floating_nodes:       Array(Node)
    )
  end # === class

  struct Window
    getter raw : Node
    getter workspace : Workspace

    def initialize(@workspace, @raw)
    end # def

    def node!
      @raw.nodes.first.not_nil!
    end # def

    def focused?
      @raw.nodes.find { |n| n.focused == true }
    end

    def name
      node!.name
    end

    def x_id
      node!.window
    end # def

    def window_rect
      node!.window_rect
    end # def

    def rect
      node!.rect
    end # def

    def geometry
      node!.rect
    end # def
  end # === struct

  struct Workspace
    getter output : Output
    getter raw : Node
    getter name : String
    getter floating_windows = Array(Window).new

    def initialize(@output, @raw)
      @name = @raw.name.not_nil!
    end # def

    def self.new(output, raw)
      w = Workspace.allocate
      w.initialize(output, raw)
      w._init(w)
      w
    end # def

    def _init(ws)
      @raw.floating_nodes.each { |fn|
        @floating_windows << Window.new(ws, fn)
      }
    end # def

    def geometry
      output.geometry
    end # def

  end # === struct

  struct Output
    getter root : Root
    getter raw : Node
    getter name : String
    getter workspaces = Array(Workspace).new
    @is_monitor : Bool

    def initialize(@root, @raw, @name)
      @is_monitor = !@name[/^[a-zA-Z]/]?.nil?
    end # def

    def self.new(root, node, name)
      o = Output.allocate
      o.initialize(root, node, name)
      o._init(o)
      o
    end # def

    def _init(o)
      @raw.nodes.each { |n|
        if n.type == "con" && n.name == "content"
          n.nodes.each { |w| @workspaces << Workspace.new(o, w) }
        end
      }
      self
    end # def

    def monitor?
      @is_monitor
    end

    def geometry
      raw.rect
    end # def

  end # === struct

  struct Root
    getter tree : Node
    getter outputs : Array(Output)

    def initialize
      @tree = I3.tree
      @outputs = Array(Output).new
    end

    def self.new
      r = Root.allocate
      r.initialize
      r._init(r)
    end # def

    def name
      tree.name
    end # def

    def _init(r)
      @tree.nodes.each { |n|
        name = n.name
        if name
          @outputs << Output.new(r, n, name)
        end
      }
      self
    end # def

  end # === struct

  extend self

  def current_window
    r = Root.new
    found = nil
    r.outputs.find { |o|
      o.workspaces.find { |w|
        w.floating_windows.find { |win|
          if win.focused?
            found = win
          end
        }
      }
    }
    found
  end # def

  def find_floating_node(node : Node)
    floats = node.floating_nodes
    found = nil
    if floats
      found = floats.find { |n| yield(n) }
      if !found
        find_floating_node(floats) { |n| yield(n) }
      else
        found
      end
    end
  end # def

  def floating_nodes
    workspace_num, output_name = `
      i3-msg -t get_workspaces | jq '.[] | select (.focused == true) | .num, .output'
    `.split

    `i3-msg -t get_tree | jq '.nodes[] | select(.name == #{output_name}) | .nodes[] | select(.name == "content") | .nodes[] | select(.type == "workspace" ) | select( .num == #{workspace_num}) | .floating_nodes[] | .nodes[] | [.window, .window_properties.class, .focused]' -c`
  end # def

  def tree
    Node.from_json( `i3-msg -t get_tree`.strip )
  end # def

  def inspect_types(io, level : Int32, n : Node)
    io << (" " * level) << n.type << " . " << (n.name || "null") << " focused: " << n.focused.inspect << '\n'
    inspect_nodes("floating_nodes", io, level + 1, n.floating_nodes)
    inspect_nodes("nodes", io, level + 1, n.nodes)
  end # def

  def inspect_nodes(name : String, io, level : Int32, nodes : Array(Node)?)
    if nodes
      if nodes.empty?
        io << (" " * level) << name << ": [empty]" << '\n'
      else
        io << (" " * level) << name << ": [#{nodes.size}]" << '\n'
        nodes.each { |n|
          inspect_types(io, level + 1, n)
        }
      end
    else
      io << (" " * level) << name << ": null" << '\n'
    end
  end # def

  def inspect_types
    level = 0
    io = IO::Memory.new
    inspect_types(io, level, tree)
    io << '\n'
    STDOUT << io
  end # def

end # === module

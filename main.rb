require "app/ray_caster"

def tick args
  defaults args
  render args
  move_player args
end

def defaults args
  args.state.map ||= [
    [1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1],
    [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1],
    [1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1],
    [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1]
  ]

  args.state.settings ||= {
    dof: 16,
    fov: 90,
    width: 1280,
    height: 720
  }

  args.state.player ||= {
    x: 600,
    y: 300,
    angle: 1
  }
end

def render args
    #render_map args
    #render_player args
    args.outputs.primitives << RayCaster.cast_rays(args)
    fps = args.gtk.current_framerate.round
    args.outputs.debug << "FPS: #{fps}"
end

def render_map args
  args.state.map.each_with_index do |row, y|
    row.each_with_index do |tile, x|
      if args.state.map[y][x] == 1
      args.outputs.solids << {
        x: 80 * x + 1,
        y: 80 * (8 - y) + 1,
        w: 78,
        h: 78
      }
      end
    end
  end
end

def render_player args
  args.outputs.sprites << {
    x: args.state.player[:x],
    y: args.state.player[:y],
    w: 40,
    h: 40,
    anchor_x: 0.5,
    anchor_y: 0.5,
    angle: args.state.player[:angle]

  }

  args.state.player[:angle].to_radians  
end

def move_player args
  p_speed = 5
  p_angle = args.state.player[:angle].to_radians

  if args.inputs.keyboard.left
    args.state.player[:angle] = (args.state.player[:angle] + 3) % 360
  elsif args.inputs.keyboard.right
    args.state.player[:angle] = (args.state.player[:angle] - 3) % 360
  end 

  if args.inputs.keyboard.down
    step_x = (Math.cos(p_angle) * p_speed)
    step_y = (Math.sin(p_angle) * p_speed)

    args.state.player[:x] -= step_x
    args.state.player[:y] -= step_y
  elsif args.inputs.keyboard.up
    step_x = (Math.cos(p_angle) * p_speed)
    step_y = (Math.sin(p_angle) * p_speed)

    args.state.player[:x] += step_x
    args.state.player[:y] += step_y
  end 
end

def to_radians
  self * Math::PI / 180
end
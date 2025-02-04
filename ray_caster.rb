module RayCaster
  extend self

  def cast_rays(args)
    settings = args.state.settings
    player_angle = args.state.player[:angle].to_radians
    ray_angle = (args.state.player[:angle] + (settings[:fov] / 2)).to_radians
    angle_step = settings[:fov].to_radians / settings[:width]

    rays = []
    rays_cast = 0
    until rays_cast >= settings[:width]
      ray = cast_ray(args, ray_angle)
      raw_distance = ray[:length]
      corrected_distance = raw_distance * Math.cos(ray_angle - player_angle)

      wall_height = (80 * settings[:height]) / corrected_distance

      vertical_slice = {
        x: rays_cast,
        y: 360,
        w: 1,
        h: wall_height,
        anchor_y: 0.5,
        primitive_marker: :solid,
        r: ray[:brightness],
        g: ray[:brightness],
        b: ray[:brightness]
      }

      rays << vertical_slice

      ray_angle = (ray_angle - angle_step) % (2 * Math::PI)
      rays_cast += 1
    end

    rays
  end

  def cast_ray(args, ray_angle)
    player_x = args.state.player[:x]
    player_y = args.state.player[:y]
    settings = args.state.settings
  
    vertical_ray = handle_verticals(player_x, player_y, ray_angle, args, settings) || {length: 1000000}
    horizontal_ray = handle_horizontals(player_x, player_y, ray_angle, args, settings) || {length: 1000000}

    shortest_ray = vertical_ray[:length] < horizontal_ray[:length] ? vertical_ray : horizontal_ray
    hit_x, hit_y = shortest_ray[:hit_coords]
  
    {
      x: player_x,
      y: player_y,
      x2: hit_x,
      y2: hit_y,
      r: vertical_ray[:length] < horizontal_ray[:length] ? 225 : 0,
      b: vertical_ray[:length] < horizontal_ray[:length] ? 0 : 255
    }

    shortest_ray
  end

  def handle_verticals(player_x, player_y, ray_angle, args, settings)
    looking_down = ray_angle > Math::PI
    looking_up = ray_angle < Math::PI

    if looking_down
      hit_y = ((player_y / 80.0).floor * 80)
      step_y = -80
    elsif looking_up
      hit_y = ((player_y / 80.0).ceil * 80)
      step_y = 80
    else
      #return nil
    end
    
    hit_x = (hit_y - player_y) / Math.tan(ray_angle) + player_x
    step_x = step_y / Math.tan(ray_angle)
  
    dof = 0
    until dof >= settings[:dof] do
      # Find pos relative to map
      map_x = ((hit_x % 1280) / 80).floor
      map_y = ((hit_y % 720) / 80).to_i
      map_y -= 1 if looking_down
  
      # If in a wall, break the loop
      break if args.state.map[(8 - map_y) % 9][map_x % 16] == 1
  
      # Otherwise, step forward in the ray
      hit_x += step_x
      hit_y += step_y
      dof += 1
    end  

    {hit_coords: [hit_x, hit_y], length: Math.hypot(hit_x - player_x, hit_y - player_y), brightness: 15}
  end

  def handle_horizontals(player_x, player_y, ray_angle, args, settings)
    looking_right = (ray_angle > 0 && ray_angle < Math::PI / 2) || (ray_angle > (3 * Math::PI / 2) && ray_angle < 2 * Math::PI)
    looking_left = ray_angle > Math::PI / 2 && ray_angle < (3 * Math::PI / 2)

    if looking_left
      hit_x = (player_x / 80).floor * 80
      step_x = -80
    elsif looking_right
      hit_x = (player_x / 80).ceil * 80
      step_x = 80
    else
      return nil
    end
  
    hit_y = (hit_x - player_x) * Math.tan(ray_angle) + player_y
    step_y = step_x * Math.tan(ray_angle)
  
    dof = 0
    until dof >= settings[:dof] do
      # Find pos relative to map
      map_x = ((hit_x % 1280) / 80).to_i
      map_y = ((hit_y % 720) / 80).floor
      map_x -= 1 if looking_left
  
      # If map_pos is in a wall, break out
      break if args.state.map[(8 - map_y) % 9][map_x % 16] == 1
  
      # Otherwise, step the ray forward
      hit_x += step_x
      hit_y += step_y
      dof += 1
    end

    {hit_coords: [hit_x, hit_y], length: Math.hypot(hit_x - player_x, hit_y - player_y), brightness: 0}
  end
end
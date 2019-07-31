-- fun generator 2000



-- make game from sims


-- make cruling game 


-- game generates a drink and you need to toss it at the right place
-- the drink rebounds and need to stop on the circle



-- generate drink
-- choose angle
-- choose strengh
-- launch

-- drink update
-- stop when speed < 0

-- if in circle then points else try again the same



-- game generate order (place)
-- places drink on stand
-- decide aim
-- decide strengh
-- launch the drink
-- if up or down then rebounds
-- if left then fall (glyph is smaller and smaller)

-- end when score == 100 or timer < 0

-- if easy then drink to toss = 4

-- if hard then drink to toss = 12

require("framework/framework")

_title = "tosser"
-- _title = "Game Template"
-- _title = "Game Template 2"

_description = "toss!"

_palette = { ["0"] = 0, 17, 14, 13, 20, 4}

_player_glyph = 0x20

_controls = {
  -- [ "up"     ] = "Move!",
  -- [ "down"   ] = "Move!",
  -- [ "left"   ] = "Move!",
  -- [ "right"  ] = "Move!",

  -- [ "cur_x"  ] = "Aim!",
  -- [ "cur_y"  ] = "Aim!",
  [ "cur_lb" ] = "Action",
  [ "cur_rb" ] = "Action",
}


bar_x = 16
bar_y = 16
bar_w = 200
bar_h = 170

function _init()
  init_objectives()
  new_drink()
end

function _update()
  state_update()
end

function _draw()
  cls
end


function init_objectives()
  objective_coord = {
    { x = GW/2, y = GH/2}
  
  
  
  }
end

function generate_order()
  if not drink then
    drink = { x = drink_start_x, y = drink_start_y, angle = 0, vx = 0, vy = 0 }
    objective = 1 + irnd(#possible_landing_zones)
  else
    if drink.x > drink_end_x then 
      drink.x = drink.x - 1
    else
      state_update = decide_angle 
      selected_angle = nil
    end
  end  
end

function decide_angle()
  temp_angle = - .25 + cos(t()) * .5    
  if btnp("cur_lb") then
    selected_angle = temp_angle
    state_update = decide_strengh
  end    
end

max_speed = 16

function decide_strengh()
  
  temp_str = cos(t())
  if btnp("cur_lb") then  
    drink.vx = temp_str * max_speed * cos(drink.angle)
    drink.vy = temp_str * max_speed * sin(drink.angle)
    state_update = update_drink
  end
end

function update_drink()
  local x = drink.x
  local y = drink.y
  local vx = drink.vx
  local vy = drink.vy
  
  x = x + vx * dt()
  y = y + vy * dt()

  vx = vx * (1  - dt())
  vy = vy * (1  - dt())
  
  if y - 8 < bar_y then y = bar_y + 8 vy = vy * -1
  elseif y + 8 > bar_y + bar_w then y = bar_y + bar_w - 8 vy = vy * -1 end
  
  if x < 16 then
    new_drink()
  end
  
  

end

function new_drink()
  drink = nil 
  state_update = generate_order
end






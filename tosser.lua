require("framework/framework")

_title = "Bar Invaders"

_description = "It's summer, and people are really thirsty."

_palette = { [0] = 0, 11, 7, 29, 20, 4, 21, 17, 26, 19}

_player_glyph = 0x60

_controls = {
  [ "cur_lb" ] = "Action",
}

bar_w = 16 * 12 + 32
bar_h = 16 * 8

drinks = {}
props = {}
timer_aim = 0
hands = {}

spawning_cooldown = 3
spawning_timer = 1

missed = 0
stolen = 0
shots  = 0

background_col = _palette[6]
ui_bar_col = _palette[7]

function _init(difficulty)

  GW = screen_w()
  GH = screen_h()
  
  gl = {
    beer_pump = 0x60,
    hand_closed = 0x17,
    hand_opened = 0x15,
  }
  
  bar_x = GW/2 - bar_w/2 - 16 - 32
  bar_y = GH/2 - bar_h/2  + 24
    
  drink_end_x = bar_x + bar_w
  drink_start_x = GW + 16
  drink_start_y = bar_y + bar_h/2
  
  init_props()
  new_drink()
  spawning_timer = spawning_cooldown

  h_speed = h_def_spd * difficulty / 100
  aim_speed = 1 + difficulty / 100
  max_thirst = 10 + 20 * difficulty / 100
  -- max_thirst = 1
  thirst_remaining = max_thirst
  displayed_thirst = max_thirst
  t_p = 3
end

function _update()
  update_drinks()
  spawning_timer = spawning_timer - dt()
  t_p = t_p *(1 -  dt() / 2)
  if spawning_timer < 0 then
    spawning_timer = spawning_cooldown * rnd(1.5)
    new_hand()
  end
  update_hands()
  
  if thirst_remaining < displayed_thirst then displayed_thirst = displayed_thirst - dt() * t_p end
  
  if displayed_thirst < 0 then 
  gameover(get_score(), get_str_score())
  end
  
end

function get_score()
  local score = 100
  score = score / (shots) * (shots - missed - stolen*2)  
  
  return mid(0, 100, score )  
  -- return 0  
end

function get_str_score()
  return {" You shot " .. shots .. " time" .. (shots>1 and "s" or "") ..",",
   " You missed " .. missed .. " time" .. (missed>1 and "s" or "") ..",",
   " and the crowd stole " .. stolen .. " drink" .. (stolen>1 and "s" or "") ..","}
end


function _draw()
  cls(background_col)
  
  draw_props()
  draw_bar()
  
  if selected_angle then
    local x = drink_end_x
    local y = drink_start_y
    color(_palette[3])
    w = 32
    for i = 0, 7 do 
      line(x, y - 3 + i, x + cos(selected_angle) * w, y + sin(selected_angle) * w)  
    end
    color(_palette[0]) 
    line(x, y, x + cos(selected_angle) * 16, y + sin(selected_angle) * 16)  
  end
    
  for i, drink in pairs(drinks) do
    draw_drink(drink)
  end
  
  draw_hands()  
  draw_ui()
  
end

function draw_ui()
  pprint("Crowd's thirst-o-meter", 0, sin(t()))
  round_rectfill(2, 18 + sin(t()), GW - 4, 16, 8, _palette[0])  
  round_rectfill(4, 20 + sin(t()), GW - 8, 12, 6, _palette[3])  
  if displayed_thirst > .5 then
    round_rectfill(4, 20 + sin(t()), (GW - 8) * displayed_thirst/ max_thirst + 2, 12, 6, _palette[0]) 
    round_rectfill(4, 20 + sin(t()), (GW - 8) * displayed_thirst/ max_thirst , 12, 6, ui_bar_col) 
  end
end

function init_props()
  for i = 0, 75 do
    add(props, { x = bar_x + bar_w + irnd(GW - bar_x - bar_w), y = bar_y + irnd(bar_h), angle = rnd(1), color = 4 + irnd(6)})
  end
end

function draw_props()
  for i, drink in pairs(props) do
    draw_drink(drink)
  end
end


function draw_bar()
  round_rectfill(bar_x-1, bar_y-1, bar_w+2, bar_h+2, 8, _palette[0])
  round_rectfill(bar_x, bar_y, bar_w, bar_h, 8, _palette[3])
  round_rectfill(bar_x + 3, bar_y + 3, bar_w - 6, bar_h - 6, 8, _palette[0])
  round_rectfill(bar_x + 4, bar_y + 4, bar_w - 8, bar_h - 8, 8, _palette[2])
  
end

function draw_drink(drink)  
  -- grip
  rectfill_angle(drink.x + cos(drink.angle + .75)*3, drink.y + sin(drink.angle + .75)*3, 16, 6, drink.angle, _palette[0], _palette[0])
  rectfill_angle(drink.x + cos(drink.angle + .75)*2, drink.y + sin(drink.angle + .75)*2, 15, 4, drink.angle, _palette[3], _palette[3])
  -- glass
  color(0)
  circfill(drink.x, drink.y, 9)
  color(_palette[3])
  circfill(drink.x, drink.y, 8)
  color(_palette[drink.color])
  circfill(drink.x, drink.y, 6)      
end

function rectfill_angle(x, y, w, h, angle, col)
  glyph(0x0B,x , y , w, h, angle, col, col, 0, 0)
end

function round_rectfill(x, y, w, h, corner_radius, col)
  local bar_x = x
  local bar_y = y
  local bar_w = w
  local bar_h = h
  
  local r = corner_radius
  local col = col
  
  color(col)
  
  circfill(bar_x + r, bar_y + r, r)
  circfill(bar_x + bar_w - r, bar_y + r, r)
  circfill(bar_x + bar_w - r, bar_y + bar_h - r, r)
  circfill(bar_x + r, bar_y + bar_h - r, r)  
  
  rectfill(bar_x, bar_y + r , bar_x + r*2, bar_y + bar_h - r)
  rectfill(bar_x + r, bar_y , bar_x + bar_w - r, bar_y + r*2)
  rectfill(bar_x + bar_w, bar_y + r, bar_x + bar_w - r*2, bar_y + bar_h - r)
  rectfill(bar_x + r, bar_y + bar_h, bar_x + bar_w - r, bar_y - r*2 + bar_h)
  
  rectfill(bar_x + r*2, bar_y + r*2, bar_x + bar_w - r *2, bar_y + bar_h - r*2)

end

max_speed = 800

function update_drinks()
  for i, drink in pairs(drinks) do 
  
    if drink.status == "spawning" then
      if drink.x > drink_end_x then 
        drink.x = drink.x - dt() * 100
      else
        drink.status = "decide_angle"
        drink.state_update = decide_angle 
        selected_angle = nil
        timer_aim = 0
      end    
      
    elseif drink.status == "decide_angle" then
      timer_aim = timer_aim + dt()
      selected_angle = .5 + cos(timer_aim / 4) * .22    
      if btnp("cur_lb") then
        shots  = shots + 1
        local selected_str = .7
        drink.vx = selected_str * max_speed * cos(selected_angle)
        drink.vy = selected_str * max_speed * sin(selected_angle)
        drink.punch = 1 - irnd(2) * 2 * selected_str
        selected_angle = nil
        new_drink()
        drink.status = "updating"
      end     
      
    elseif drink.status == "updating" then
      local d = drink
      d.punch = d.punch  * ( 1 - dt())
      d.angle = d.angle - (d.punch * dt())
      d.x = d.x + d.vx * dt()
      d.y = d.y + d.vy * dt()

      d.vx = d.vx * (1  - dt() * 3)
      d.vy = d.vy * (1  - dt() * 3)
      
      if d.y - 8 < bar_y then 
        d.y = bar_y + 8 d.vy = d.vy * -.5 d.vx = d.vx * .5
      elseif d.y + 8 > bar_y + bar_h then 
        d.y = bar_y + bar_h - 8 d.vy = d.vy * -.5 d.vx = d.vx * .5
      end
      
      if d.x < - 16 or d.vx * d.vx + d.vy * d.vy < 13 then
        missed = missed + 1
        screenshake(8)
        del_at(drinks, i)
      end 
    elseif drink.status == "is_caught" then
      drink.x = drink.x - 100 * dt()    
      if drink.x < -16 then del_at(drinks,i) end
    end
  end
  
end

function new_drink()
  add(drinks, { x = drink_start_x, y = drink_start_y, angle = 0, vx = 0, vy = 0, color = 4 + irnd(6), status = "spawning"})
end

function new_hand()
  add(hands, {x = - 32, y = bar_y + 16 + irnd(bar_h - 48), speed = 1, angle = 0, pattern = 0, state = "opened", timer = 0})
end

knockback_v = 6
h_def_spd = 25
function update_hands()
  
  for i, hand in pairs(hands) do
    if knockback then hand.x = hand.x - knockback_v end
    if not hand.caught then
      hand.timer = hand.timer + dt()      
      if hand.timer > .3 then 
        hand.timer = 0
        hand.is_closed = not hand.is_closed
      end
      if hand.pattern == 0 then
        hand.x = hand.x + h_def_spd * (1  + cos(hand.timer * 3.33)*.5) * dt()
      end
      
      if hand.x > bar_x + bar_w + 16 then 
        hurt(hand) 
      end 
        
      for j, drink in pairs(drinks) do
        if drink.status == "updating" and dist(drink.x, drink.y, hand.x, hand.y) < 16 then
          drink.status = "is_caught"        
          t_p = 3
          thirst_remaining = thirst_remaining - 1
          drink.x = drink.x - knockback_v      
          hand.caught = true          
          hand.is_closed = true 
          screenshake(4)
          knockback = true
        end
      end
    else
      hand.x = hand.x - 100 * dt()    
      if hand.x < -16 then del_at(hands,i) end
    end
  end
  
  if knockback then
    for i, hand in pairs(hands) do
      hand.x = hand.x - knockback_v
    end
  end
  knockback = false
end

function draw_hands()
  for i, hand in pairs(hands) do
    color(_palette[0])
    rectfill( -16, hand.y - 6, hand.x, hand.y + 6)
    local gl = (hand.is_closed and gl.hand_closed or gl.hand_opened)
    outlined_glyph(gl, hand.x, hand.y, 16, 16, hand.angle + .5 - .125, _palette[3], _palette[0], _palette[0])
    color(_palette[3])
    rectfill( -16, hand.y - 5, hand.x, hand.y + 5)
  end
end

function hurt(hand)  
  t_p = 3
  thirst_remaining = thirst_remaining - 3
  stolen = stolen + 1
  hand.caught = true         
  add(drinks, { x = hand.x, y = hand.y, angle = rnd(1), vx = 0, vy = 0, color = 4 + irnd(6), status = "is_caught"})
end







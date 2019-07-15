require("framework/framework")

_title = "Fishing Game"
-- _name = "Game Template"
-- _name = "Game Template 2"

_description = "Some test indeed !"

_palette = { ["0"] = 0, 17, 14, 13, 20, 4}


_controls = {
  [ "up"     ] = "Move!",
  [ "down"   ] = "Move!",
  [ "left"   ] = "Move!",
  [ "right"  ] = "Move!",

  [ "A"      ] = "Jump!",
  [ "B"      ] = "Crouch!",

  [ "cur_x"  ] = "Aim!",
  [ "cur_y"  ] = "Aim!",
  [ "cur_lb" ] = "Shoot!",
  [ "cur_rb" ] = "Send movie to director!"
}

local GW, GH = 0, 0
player = {x = 0, y = 0, w = 16, h = 16, a = 0}
bubbles = {} -- bubbles around player
bubble_timer = 1

bullets = {}
bullet_timer = .1
bullet_cooldown = .5

targets = {}
spawn_target_timer = 1
spawn_target_cooldown = .7

remaining_targets = 20

function _init()
  GW = screen_w()
  GH = screen_h()
  player.x, player.y = GW / 2, GH - 16
  player.a = 0
  
  g_spr = {
    mouse  = 0x00,
    player = 0x20,
    bubble = 0x30,
    rope   = 0x50,
    target = 0x31,
    fence  = 0x33,
    ground = 0x34
  }
  
  printp_color (_palette[6], _palette[4], _palette[3])
  
  init_ground() 
  init_ropes() 
  
  -- began_game_over = true
  
end

function init_ground()
  ground = {}
  for i = 1, 3 do
    local strip = {}
    for j = 1, GW/16 do
      add(strip, { v = - 1 + irnd(4) * (irnd(3) == 0 and 1 or 0), a = rnd(1)})
    end
    add(ground, strip)
  end
end

function init_ropes()
  ropes = {}
  add(ropes, {y = 16, step = rnd(1)})
  add(ropes, {y = 16*4, step = rnd(1)})

end


function _update()
  
  update_player()
  
  update_targets()
  
  update_bubbles()
  
  update_bullets()
  
  -- if btnp("A") or btnp("cur_rb") then
    -- add(_objects, {spr = 0x03,  p = {x = btnv("cur_x"), y = btnv("cur_y")}})  
  -- end
  
  -- if btnp("cur_lb") then
    -- local i = 0
    -- for id, game in pairs(get_game_list()) do
      -- local x = GW / 6 + i * GW/3
      -- local y = 50
      
      -- local x_mouse = btnv("cur_x")
      -- local y_mouse = btnv("cur_y")
      
      -- if point_in_rect(x_mouse, y_mouse, x, y, x + 15, y + 15) then load_game(id) end  
      
      -- i = i + 1
      
    -- end
  -- end
  
  if remaining_targets == 0 and count(targets) == 0 and not began_game_over then
    began_game_over = true
    begin_game_over()
  end
  if began_game_over then
    t_display_game_over = t_display_game_over - dt()
  end
end

function begin_game_over()
  log("game over!") 

end

function update_player()
  player.x = player.x - btnv("left") + btnv("right")
  player.y = player.y - btnv("up") + btnv("down")
  
  if player.x < 0 then player.x = 0 
  elseif player.x > GW then player.x = GW end
  
  if player.y < GH - 16*2 then player.y = GH - 16*2
  elseif player.y > GH then player.y = GH end
  
  player.a = atan2(btnv"cur_x" - player.x, btnv"cur_y" - player.y)
end

function update_bubbles()

  bubble_timer = bubble_timer - dt()  
  
  if bubble_timer < 0 then
    new_bubble()
  end  
  
  for ind, bubble in pairs(bubbles) do
    bubble.y = bubble.y - dt() * 64
    bubble.x = bubble.x + cos(t()) * (.5 + rnd(.5))
    
    bubble.a = bubble.a - dt() * 2 * bubble.rotation
  end

end

function update_bullets()
  bullet_timer = bullet_timer - dt()  
    
  if btn("cur_lb") then
    if bullet_timer < 0 then
      new_bullet()
    end      
  end
  
  for ind, bullet in pairs(bullets) do
    bullet.x = bullet.x + bullet.speed * cos(bullet.a)
    bullet.y = bullet.y + bullet.speed * sin(bullet.a)
    bullet.r = bullet.r - dt() * 2
    
    for i, target in pairs(targets) do
      local t_y = get_rope_y_offset(ropes[target.rope + 1].y) + ropes[target.rope + 1].y
      if dist(bullet.x, bullet.y, target.x, t_y) < 16 then
        targets[i] = nil      
        bullets[ind] = nil      
        give_points(20)
      end  
    end  
  end
  
end

function update_targets()
  spawn_target_timer = spawn_target_timer - dt()  
  
  if spawn_target_timer < 0 and remaining_targets > 0 then
    new_target()
  end  
  
  for ind, target in pairs(targets) do
    target.x = target.x + target.speed * dt() * target.dir
    if target.x < -32 or target.x > GW + 32 then
      targets[ind] = nil
    end    
  end
end

function new_target()
  spawn_target_timer = spawn_target_cooldown / 2 + rnd(spawn_target_cooldown)
  remaining_targets = remaining_targets - 1
  local rope = irnd(#ropes)
  local dir
  
  if rope == 0 then dir = 1 else dir = -1 end
  
  add(targets, { x = - 16 + (dir == -1 and GW + 16 or 0), rope = rope, dir = dir, speed = GW / 2 } )
end

function new_bullet()
  bullet_timer = bullet_cooldown
  add(bullets, { x = player.x + cos(player.a) * 10, y = player.y + sin(player.a) * 10, s = 32, a = player.a, r = 0, speed = 3 } )
end

function new_bubble()
  bubble_timer = .5 + rnd(1)
  add(bubbles, { x = player.x + cos(player.a) * 10, y = player.y + sin(player.a) * 10, s = 16, a = rnd(1), rotation = (irnd(100) % 2 == 0 and 1 or -1) } )
end

function _draw()
  cls(_palette[1])
    
  -- list of games
  -- this should be in end screen of framework, testing purpose only
    -- local i = 0
    -- local col = _palette[5]
    -- color(col)
    -- for id, game in pairs(get_game_list()) do
      -- local x = GW / 6 + i * GW/3
      -- local y = 50
      -- color(col)
      -- print(id, x, y)
      -- print(game.name, x - str_px_width(game.name)/2, y + 15)
      -- rectfill(x, y, x + 15, y + 15, col)
      -- i = i + 1
    -- end
  --
  
  draw_ground()
  
  draw_fences()
  draw_player()  
  
  draw_remaining()
  
  draw_ropes()
  draw_targets()
  
  draw_bullets()  
  draw_bubbles()  
  draw_mouse()
  
  if began_game_over then
    draw_game_over()
  end
  
end

t_display_game_over = 5
max_t_d = 5

function draw_game_over()
  
  if t_display_game_over > 0 then
    -- local t_transition = max_t_d/3
    local t_transition = { max_t_d /4, max_t_d/4, max_t_d/2 }
    local s_y = -15
    local f_y = GH/4
    local y    
    
    if t_display_game_over > max_t_d - t_transition[1] then
      y = s_y + easeInOut(max_t_d - t_display_game_over, 0, f_y, t_transition[1])
      
    elseif t_display_game_over < t_transition[2] then
      y = f_y + s_y - easeInOut(t_transition[2] - t_display_game_over, 0, f_y, t_transition[2])
      
    else
      y = f_y + s_y   
    end
    local str = "Game over!"
    pprint(str, GW/2 - str_px_width(str)/2 , y + sin(t() / 3) * 3)

  end
end

function draw_ground()
  for i, strip in pairs(ground) do
    for j, rect in pairs(strip) do
      if rect.v ~= -1 then
        glyph(g_spr.ground + rect.v, j * 16 - 8, GH + (i - 3) * 16, 16, 16, rect.a, _palette[0])
      end
    end
  end
end

function draw_player()
  outlined_glyph(g_spr.player, player.x, player.y, player.w, sgn(cos(player.a)) * (player.h + 2*sin(t())), player.a, _palette[2], _palette[3], 0)
end

function draw_bullets()    
  for ind, bullet in pairs(bullets) do
    outlined_glyph(g_spr.bubble, bullet.x, bullet.y, bullet.s, bullet.s, bullet.r, _palette[2], _palette[3], 0)
  end  
end

function draw_bubbles()
  for ind, bubble in pairs(bubbles) do
    outlined_glyph(g_spr.bubble, bubble.x, bubble.y, bubble.s, bubble.s, bubble.a, _palette[2], _palette[3], 0)
  end
end

function draw_fences()
  for i = 0, GW/16 do
    outlined_glyph(g_spr.fence,  i * 16 - 8, GH - 16 * 2 - 8, 16, 16, 0, _palette[0], _palette[0], 0)
  end
  for i = 0, GW/16 do
    glyph(g_spr.fence,  i * 16 - 8, GH - 16 * 2 - 8, 16, 16, 0, _palette[2], _palette[3], 0)
  end
end

function draw_ropes()  
  for i, rope in pairs(ropes) do draw_rope(rope.y, rope.step, i) end
end

function draw_rope(y, step, i)
   
  local x_offset = 16 * ((t()* 7.8) % 1) * (i == 1 and 1 or -1 )
   
  for i = -1, GW/16 + 1 do
    outlined_glyph(g_spr.rope,x_offset +   i * 16 - 8, y + get_rope_y_offset( i * GW/16, step ) - 8, 16, 16, .25, _palette[0], _palette[0  ], 0)
  end
  for i = -1, GW/16 + 1 do 
    glyph(g_spr.rope, x_offset +  i * 16 - 8, y + get_rope_y_offset( i * GW/16, step ) - 8, 16, 16, .25, _palette[5], _palette[2], 0)
  end
  
end

function draw_targets()
  for i, target in pairs(targets) do
    local y = get_rope_y_offset(target.x, ropes[target.rope + 1].step ) + ropes[target.rope + 1].y
    
    outlined_glyph(g_spr.target, target.x + 8, y + 2, 16, 16, 0, 0, 0, 0)
    outlined_glyph(g_spr.target, target.x + 8, y , 16, 16, 0, _palette[2], _palette[3], 0)
  end
end

function get_rope_y_offset( x, step)

  local amp = 6
  local speed = 1 / 3
  local step = step or 0
  
  if x > GW / 2 then
    return amp * cos(t() * speed + step) * ((GW - x)/(GW/2))
  elseif x == GW / 2 then
    return amp * cos(t() * speed + step)
  else
    return amp * cos(t() * speed + step) * ((x)/(GW/2))
  end
  
end

function draw_remaining()

  local x = GW / 2 - 60
  local y = GH / 2 + sin(t() / 4) * 2

  pprint("Remaining ", x, y)
  
  x = x + str_px_width("Remaining ")
  
  outlined_glyph(g_spr.target, x + 8, y + 8 + 2, 16, 16, 0, 0, 0, 0)
  
  outlined_glyph(g_spr.target, x + 8, y + 8, 16, 16, 0, _palette[2], _palette[3], 0)
  
  x = x + 17
  
  pprint(": " .. remaining_targets, x, y)

end

function draw_mouse()
  outlined_glyph(g_spr.mouse, btnv("cur_x"), btnv("cur_y"), 8 , 8 , 0, _palette[4], _palette[5], 0)
end

function point_in_rect(xp, yp, x1, y1, x2, y2)
  return xp > x1 and xp < x2 and yp > y1 and yp < y2
end

function count(tab)
  if not tab then return end
  local nb = 0
  for i, j in pairs(tab) do nb = nb + 1 end
  return nb  
end

function easeInOut (timer, value_a, value_b, duration)
  
  timer = timer/duration*2  
	if (timer < 1) then return value_b/2*timer*timer + value_a end
  
	timer = timer - 1
  
 	return -value_b/2 * (timer*(timer-2) - 1) + value_a
end 

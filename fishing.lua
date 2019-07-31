require("framework/framework")

_title = "Rocky Fishing"
_description = "Get the fish! Avoid boots! Don't touch the rocky walls!"

_player_glyph = 0x22

_controls = {
  [ "right"  ] = "Move the hook",
  [ "down"   ] = "Move the hook",
  [ "left"   ] = "Move the hook",
  [ "up"     ] = "Move the hook",
}


local hook_x = 128
local hook_y = 64
local hook_bx = 0
local hook_by = 0
local hook_vx = 0
local hook_vy = 0
local hook_a = 0

local fishing_line = {}

local surface_y = 32

local progress = 0
local length = 512
local width = 32
local lives = 3

local spawn_timer = 0
local spawn_prog = 0
local boot_chance = 50

local bubble_t = 0
local bubble

local fish  = {}
local boots = {}
local bubbles_a = {}
local bubbles_b = {}

local chest_w = 64
local chest_h = 48
local chest_x = 128
local chest_y = length

local end_it
local treasure


function _init(difficulty)

  init_fishing_line()
  
  length = 1024 + difficulty * 32
  width = (0.4 - min(difficulty/100, 1) * 0.32) * screen_w()
 
  boot_chance = mid(20 + difficulty/100*55 , 25, 80)
  
  chest_y = length - chest_h/2 + 4
  
  init_walls()
  gen_algae()
  
  for i = 1,3 do
    local s = create_fish(rnd(256), 96+rnd(96))
    if s.big then
      s.big = false
      s.w = s.w/2
      s.h = s.h/2
    end
  end
end

function _update()
--  if btnp("cur_rb") then
--    screenshot()
--  end
  
  if end_it then
    freeze(0.5)
    the_end()
  end

  bubble_t = bubble_t - dt()
  if bubble_t < 0 and #bubbles_a + #bubbles_b < 64 then
    bubble = true
    bubble_t = 0.03
  else
    bubble = false
  end
  
  update_hook()
  
  foreach(fish, update_fish)
  foreach(boots, update_boot)
  
  foreach(bubbles_a, update_bubble)
  foreach(bubbles_b, update_bubble)
  
  local lim = 96
  if hook_y > progress + lim then
    progress = min(lerp(progress, hook_y-lim, 3 * dt()), length - 190)
  end
  
  
  if flr(progress / 24) > spawn_prog then
    spawn_prog = progress/24
    spawn_timer = 0
  end
  
  spawn_timer = spawn_timer - dt()
  if spawn_timer < 0 then
    if chance(boot_chance) then
      create_boot(rnd(256), progress + 192+16 + rnd(64))
    else
      create_fish(rnd(256), progress + 192+16 + rnd(64))
    end
    
    spawn_timer = 2+rnd(2)
  end

  
  if abs(hook_y - chest_y) < chest_h/2 + 8 and abs(hook_x - chest_x) < chest_w/2 + 8 then
    treasure = true
    end_it = true
  end
  
  if wall_collision(hook_x, hook_y, 8, 8) then
    end_it = true
  end
end


function _draw()
  cls(18)
  
  camera(0, progress)
  
  foreach(bubbles_a, draw_bubble)

  draw_hook()
  
  for i = max(#fish - 16, 1), #fish do
    draw_fish(fish[i])
  end
--  foreach(fish, draw_fish)
  foreach(boots, draw_boot)
  
  foreach(bubbles_b, draw_bubble)
  
  if progress < 64 then
    draw_surface()
  end
  
  draw_chest()
  draw_algae()
  draw_walls()
  
  if end_it then
    if treasure then
      circfill(hook_x, hook_y, 12, 29)
      circfill(chest_x, chest_y, 48, 29)
      draw_hook()
      draw_chest()
    else
      circfill(hook_x, hook_y, 12, 29)
      draw_hook()
    end
  end
end



function update_hook()
  if hook_y < max(surface_y+16, progress) then
    hook_vy = hook_vy + dt() * 5
  else
    local acc = 3
    hook_vx = hook_vx + acc * (btnv("right") - btnv("left")) * dt()
    hook_vy = hook_vy + acc * (btnv("down") - btnv("up")) * dt()
  end
  
  local v = hook_x - screen_w()/2
  if abs(v) > screen_w()/2 then
    hook_vx = hook_vx + dt() * 5 * sgn(-v)
  end
  
  hook_x = hook_x + hook_vx
  hook_y = hook_y + hook_vy
  
  hook_a = hook_a + dt() * 2 * angle_diff(hook_a, atan2(hook_vx, hook_vy))
  
  hook_vx = lerp(hook_vx, 0, dt())
  hook_vy = lerp(hook_vy, 0.5, dt())
  
  update_fishing_line()
  
  hook_bx = hook_x + 7.5 * cos(hook_a)
  hook_by = hook_y + 7.5 * sin(hook_a)
  
  
  for s in all(fish) do
    if (not s.hooked) and abs(s.x - hook_x) < s.w/2+6 and abs(s.y - hook_y) < s.h/2+6 then
      s.hooked = true
      s.white = 0.05
      screenshake(2)
    end
  end
  
  for s in all(boots) do
    if (not s.hooked) and abs(s.x - hook_x) < s.w/2+6 and abs(s.y - hook_y) < s.h/2+6 then
      s.hooked = true
      s.white = 0.05
      screenshake(4)
    end
  end

  
  if bubble and chance(20) then
    create_bubble(hook_x + give_or_take(6), hook_y + give_or_take(6))
  end
end

function draw_hook()
  outlined_glyph(0x22, hook_x, hook_y, 16, 16, hook_a-0.25, 27, 19, 0)
  draw_fishing_line()
end



function the_end()
  local f, fb = 0, 0
  for _,s in pairs(fish) do
    if s.hooked then
      if s.big then
        fb = fb + 1
      else
        f = f + 1
      end
    end
  end
  
  local b = 0
  for _,s in pairs(boots) do
    if s.hooked then
      b = b + 1
    end
  end
  
  local stats = {}
  
  if f > 0 then
    add(stats, "You caught "..f.." small fish! ("..f.." x 5pts)")
  end
  
  if fb > 0 then
    add(stats, "You caught "..fb.." big fish! ("..fb.." x 15pts)")
  end
  
  if b > 0 then
    add(stats, "You caught "..b.." boots! ("..b.." x -20pts)")
  end
  
  if treasure then
    add(stats, "You got the treasure!! (+ 50pts)")
  end
  
  local score = f*5 + fb*15 - b*20 + (treasure and 50 or 0)
  
--  add(stats, "Total: "..score)

  gameover(score, stats)
end

local left_wall, right_wall
local wall_step = 4
function wall_collision(x, y, w, h)
  local pts = {
    { x = x - w/2, y = y - h/2 },
    { x = x + w/2, y = y - h/2 },
    { x = x - w/2, y = y + h/2 },
    { x = x + w/2, y = y + h/2 }
  }
  
  for _,p in pairs(pts) do
    if p.y > length then
      return true
    end
  
    local va = p.y - p.y % wall_step
    local vb = (p.y % wall_step) / wall_step
    
    local lx = lerp(
      left_wall[va],
      left_wall[va + wall_step],
      vb
    )
    
    local rx = lerp(
      right_wall[va],
      right_wall[va + wall_step],
      vb
    )
    
    if p.x < lx or p.x > rx then
      return true
    end
  end
  
  return false
end

local wall_colors
function draw_walls()
--  local c0, c1, c2, c3, c4 = 0, 13, 6, 5, 2
--  local c0, c1, c2, c3, c4 = 0, 3, 19, 27, 28
--  local c0, c1, c2, c3, c4 = 0, 28, 27, 19, 3
--  local c0, c1, c2, c3, c4 = 0, 2, 5, 6, 13
--  local c0, c1, c2, c3, c4 = 0, 8, 9, 10, 16
  
  local c0, c1, c2, c3, c4 = unpack(wall_colors)

  local btm = progress + screen_h()
  
  local last_lx, last_rx
  for y = flr(progress), min(btm, length) do
    local va = y - y % wall_step
    local vb = (y % wall_step) / wall_step
    
    local lx = lerp(
      left_wall[va],
      left_wall[va + wall_step],
      vb
    )
    
    local rx = lerp(
      right_wall[va],
      right_wall[va + wall_step],
      vb
    )
    
    local rx = rx-256
    local llx, lrx, nlx, nrx
    
    llx, lrx, nlx, nrx = -8, 263, 0.4*lx, 256+rx*0.4
    rectfill(llx, y, nlx, y, c4)
    rectfill(nrx, y, lrx, y, c4)
    
    llx, lrx, nlx, nrx = nlx, nrx, 0.85*lx, 256+rx*0.85
    rectfill(llx, y, nlx, y, c3)
    rectfill(nrx, y, lrx, y, c3)
    
    llx, lrx, nlx, nrx = nlx, nrx, 0.9*lx, 256+rx*0.9
    rectfill(llx, y, nlx, y, c2)
    rectfill(nrx, y, lrx, y, c2)
    
    llx, lrx, nlx, nrx = nlx, nrx, lx, 256+rx
    rectfill(llx, y, nlx, y, c1)
    rectfill(nrx, y, lrx, y, c1)

    rectfill(lx-1, y, lx, y, c0)
    rectfill(256+rx, y, 256+rx+1, y, c0)
    
    last_lx = lx
    last_rx = rx
  end
  
  if btm > length then
    -- draw ground
    
    clip(0, flr(length)+1, 256, ceil(btm-length))
    
    local lx, rx = last_lx, last_rx
    
    local llx, lrx, nlx, nrx
    local x, y, r
    y = length - 64
    
    rectfill(0, length+1, 256, btm, c4)
    
    nlx, nrx = 0.4*lx, 256+rx*0.4
    llx, lrx, nlx, nrx = nlx, nrx, 0.85*lx, 256+rx*0.85
    x = lerp(llx, lrx, 0.5)
    r = dist(x, y, llx, length)
    circfill(x, y, r, c3)
    
    y = y - 64
    llx, lrx, nlx, nrx = nlx, nrx, 0.9*lx, 256+rx*0.9
    x = lerp(llx, lrx, 0.5)
    r = dist(x, y, llx, length)
    circfill(x, y, r, c2)
    
    y = y - 64
    llx, lrx, nlx, nrx = nlx, nrx, lx, 256+rx
    x = lerp(llx, lrx, 0.5)
    r = dist(x, y, llx, length)
    circfill(x, y, r, c1)
    
    
    y = y - 256
    x = lerp(lx, 256+rx, 0.5)
    r = dist(x, y, lx, length)
    circfill(x, y, r, c0)

    clip()
  end
end

function init_walls()
  log("Generating walls...", "...")
  
  wall_colors = pick{
    {0, 3, 19, 27, 28},
    {0, 2, 5, 6, 13},
    {0, 8, 9, 10, 16},
    {0, 2, 5, 4, 21},
    {0, 5, 4, 20, 27}
  }

  local center = gen_random_curve(7)
  local left   = gen_random_curve()
  local right  = gen_random_curve()
  
  local midx  = screen_w()/2
  local c_var = (0.9 * screen_w() - width)/2
  
  left_wall, right_wall = {}, {}
  
  local safe_space = 128
  
  for y = 0, length + wall_step, wall_step do
    local width = width
    local c_var = c_var
    
    if y < surface_y + safe_space then
      local v = y / (surface_y + safe_space)
      width = lerp(256, width, v*2-1)
      c_var = lerp(0, c_var, max(v*2-1, 0))
    elseif y > length - safe_space then
      local v = min( (1 + (y - length) / safe_space) * 2, 1)
      c_var = lerp(c_var, 0, v)
      
      --if y > length - 3 then
      --  width = lerp(width, 64, (y - length + 5) / 5)
      --else
        width = lerp(width, 64, v)
      --end
    end
    
    local c = midx + c_var * evaluate_curve(center, y/4000)
    
    local lw = min(c - width/2, 64)/2
    local rw = min(256 - (c + width/2), 64)/2
    
    local l = evaluate_curve(left, y/4000 *2)
    local r = evaluate_curve(right, y/4000 *2)
    
    left_wall[y]  = c - width/2 - (1+l)*lw
    right_wall[y] = c + width/2 + (1+r)*rw
  end
  
  log("Done generating walls!", ":")
end


function draw_chest()
  outlined_glyph(0x27, chest_x, chest_y, chest_w, chest_h, 0.025, 6, 2, 0)

  local cols = {
    {1,2},
    {2,5},
    {5,6},
    {6,13},
    {13,14},
    {14,24},
    {13,14},
    {6,13},
    {5,6},
    {2,5}
  }
  
  for i = 0, 7 do
    local y = progress+192-i*8
    clip(0, y-8, 256, 8)
    
    local c = cols[flr(i - 10*t()) % #cols + 1]
    outlined_glyph(0x27, chest_x, chest_y, chest_w, chest_h, 0.025, c[2], c[1], 0)
  end
  
  clip()
end


local rainbow_ramps = {
  { 29, 24, 14, 13, 6 },
  { 29, 25, 15, 10, 8 },
  { 29, 26, 16, 9,  8 },
  { 29, 26, 17, 18, 3 },
  { 29, 27, 20, 19, 3 },
  { 29, 22, 21, 4,  2 },
  { 29, 22, 12, 5,  2 },
  { 29, 14, 13, 6,  2 }
}

function update_fish(s)
  s.animt = s.animt + dt()
  
  if s.white then
    s.white = s.white - dt()
    if s.white <= 0 then
      s.white = false
    end
  end
  
  if s.hooked then
    s.y = s.y + s.vy * dt()
    s.x = s.x + s.vx * dt()
  
    d = dist(hook_bx-s.x, hook_by-s.y)
    
    local ox,oy = s.x, s.y
    
    md = s.w/2
    if d > md +1 then
      s.x = lerp(s.x, hook_bx, 1-md/d)
      s.y = lerp(s.y, hook_by, 1-md/d)
    elseif d < md -1 then
      s.x = lerp(s.x, hook_bx, 1-md/d)
      s.y = lerp(s.y, hook_by, 1-md/d)
    end
    
    s.vx = s.vx + dt() * (s.x - ox)
    s.vy = s.vy + dt() * (s.y - oy)
    
    if bubble and chance(5) then
      create_bubble(s.x + give_or_take(6), s.y + give_or_take(6))
    end
    
    return
  end
  
--  s.y = s.ay + 3 * cos(s.animt)
  
  s.x = s.x + (0.5*cos(s.vvx*s.animt-0.1)+1) * s.vx * dt()
  
  if bubble and chance(10) then
    create_bubble(s.x + sgn(s.vx) * s.w*0.45, s.y)
  end
  
  local rp = s.x - 128
  if abs(rp) > 136 and sgn(rp) == sgn(s.vx) then
    del(fish, s)
  end
end

function draw_fish(s)
  local c0 = s.ramp[mid(flr(3.5+ cos(s.animt*2) + cos(s.animt/4)), 1, 5)]
  local c1 = s.ramp[5]
  
  if s.hooked then
    local a = atan2(hook_bx - s.x, hook_by - s.y)
    
    if s.white then
      outlined_glyph(s.g, s.x, s.y, s.w, s.h, a, 29, 29, 0)
    else
      outlined_glyph(s.g, s.x, s.y, s.w, s.h, a, c0, c1, 0)
    end
  else
    outlined_glyph(s.g, s.x, s.y, sgn(s.vx) * (1 + 0.2*sqr(cos(s.vvx * 0.5 * s.animt))) * s.w, (1 + 0.2*sqr(sin(s.vvx * 0.5 * s.animt))) * s.h, 0, c0, c1, 0)
  end
end

local fish_colors = {
  {12, 4}, {13, 6}, {14, 13}, {15, 10}, {17, 18}, {20, 19}, {29, 28},
  {24, 14}, {25,15}, {26, 16}, {23, 22}, {22, 21}, {21, 4},
  {10, 9}, {9, 8}, {6, 5}, {11, 7}
}

function create_fish(x, y)
  local col = pick(fish_colors)
  local b = chance(10)
  
  local s = {
    x     = x,
    y     = y,
    ay    = y,
    vy    = 0,
    vx    = sgn(128-x) * (20 + rnd(30)),
    vvx   = 0.5 + rnd(1),
    animt = rnd(1),
    w     = 10 + rnd(8),
    h     = 8 + rnd(8),
    g     = 0x20 + irnd(2),
    big   = b,
    c0    = col[1],
    c1    = col[2],
    ramp  = pick(rainbow_ramps)
  }
  
  if s.big then
    s.w = max(18, s.w*2)
    s.h = max(18, s.h*2)
  end
  
  add(fish, s)
  return s
end



function update_boot(s)
  s.animt = s.animt + dt()
  
  if s.white then
    s.white = s.white - dt()
    if s.white <= 0 then
      s.white = false
    end
  end
  
  if s.hooked then
    s.y = s.y + s.vy * dt()
    s.x = s.x + s.vx * dt()
  
    d = dist(hook_bx-s.x, hook_by-s.y)
    
    local ox,oy = s.x, s.y
    
    md = s.w/2
    if d > md +1 then
      s.x = lerp(s.x, hook_bx, 1-md/d)
      s.y = lerp(s.y, hook_by, 1-md/d)
    elseif d < md -1 then
      s.x = lerp(s.x, hook_bx, 1-md/d)
      s.y = lerp(s.y, hook_by, 1-md/d)
    end
    
    s.vx = s.vx + dt() * (s.x - ox)
    s.vy = s.vy + dt() * (s.y - oy)
    
    if bubble and chance(5) then
      create_bubble(s.x + give_or_take(6), s.y + give_or_take(6))
    end
  
    return
  end
  
  s.y = s.y + s.vy * dt()
  
  if bubble and chance(10) then
    create_bubble(s.x + give_or_take(6), s.y + give_or_take(6))
  end
  
  if s.y > progress + 256 then
    del(boots, s)
  end
end

function draw_boot(s)
  if s.hooked then
    local a = atan2(hook_bx - s.x, hook_by - s.y)
    
    if s.white then
      outlined_glyph(s.g, s.x, s.y, s.w, s.h, a, 12, 12, 0)
    else
      outlined_glyph(s.g, s.x, s.y, s.w, s.h, a, s.c0, s.c1, 0)
    end
  else
    outlined_glyph(s.g, s.x, s.y, s.facing_w * s.w, s.facing_h * s.h, s.a + 0.05 * cos(s.animt * 0.1), s.c0, s.c1, 0)
  end
end

local boot_colors = {
  {6, 5}, {13, 6}, {14, 13}, {11, 9}
}

function create_boot(x, y)
--  local col = pick(boot_colors)
  local ramp = pick(rainbow_ramps)
  
  local s = {
    x        = x,
    y        = y,
    vy       = 15,
    vx       = 0,
    facing_w = (irnd(2) - 0.5) * 2,
    facing_h = (irnd(2) - 0.5) * 2,
    a        = rnd(1),
    animt    = rnd(1),
    w        = 14 + rnd(6),
    h        = 14 + rnd(6),
    g        = 0x24,
    c0       = ramp[4], --col[1],
    c1       = ramp[5]--col[2]
  }
  
  add(boots, s)
  return s
end


function update_fishing_line()
  local h = fishing_line[#fishing_line]
  h.x = hook_x - 6*cos(hook_a)
  h.y = hook_y - 6*sin(hook_a)
  
  local e = fishing_line[1]
  e.x = screen_w()/2
  e.y = max(surface_y, progress-16)

  for i = #fishing_line-1, 2, -1 do
    local p,pp,fp,md,d = fishing_line[i], fishing_line[i+1], fishing_line[i-1], 12
    
    p.y = p.y + 10*dt()
    
    d = dist(pp.x-p.x, pp.y-p.y)
    if d > md then
      p.x = lerp(p.x, pp.x, 1-md/d)
      p.y = lerp(p.y, pp.y, 1-md/d)
    else
      p.x = lerp(p.x, pp.x, 0.4 * dt())
      p.y = lerp(p.y, pp.y, 0.4 * dt())
    end
    
    d = dist(fp.x-p.x, fp.y-p.y)
    if d > md then
      p.x = lerp(p.x, fp.x, 0.1*(1-md/d))
      p.y = lerp(p.y, fp.y, 0.1*(1-md/d))
    else
      p.x = lerp(p.x, fp.x, 0.5 * dt())
      p.y = lerp(p.y, fp.y, 0.5 * dt())
    end
  end
end

function draw_fishing_line()
  for i = #fishing_line-1, 1, -1 do
    local p,pp = fishing_line[i], fishing_line[i+1]
    line(p.x, p.y, pp.x, pp.y, 0)
  end
end

function init_fishing_line()
  for i = 1, 64 do
    fishing_line[i] = { x = screen_w()/2, y = surface_y+i*0.01}
  end
end



function update_bubble(s)
  s.x = s.x + s.vx * dt()
  s.y = s.y + s.vy * dt()
  
  s.vx = lerp(s.vx, 0, 1 * dt())
  s.vy = lerp(s.vy, -20, 1 * dt())
  
  if s.y - s.size/2 < progress then
    if s.b then
      del(bubbles_b, s)
    else
      del(bubbles_a, s)
    end
  end
end

function draw_bubble(s)
  glyph(0x06, s.x, s.y, s.size, s.size, 0.125, s.c, 17)
end

function create_bubble(x, y)
  local a,spd = rnd(1), rnd(15)
  
  local b = chance(50)
  
  local s = {
    x = x,
    y = y,
    vx = spd * cos(a),
    vy = spd * sin(a),
    size = 2 + rnd(4),
    b = b,
    
    c = pick{17, 16, 16, 26, 26, 29}
  }
  
  if b then
    add(bubbles_b, s)
  else
    add(bubbles_a, s)
  end
end


local algae = {}
local function new_algae(x, y, a)
  local s = {
    x = x,
    y = y,
    a = a,
    t = rnd(1000)
  }
  
  if chance(40) then -- regular algae
    merge_tables(s, {
      g = 0x25,
      w = 6 + rnd(10),
      h = 16 + rnd(10),
      a = a - 0.25,
      
      cols = pick{
        {15, 10},
        {16, 10},
        {10, 9},
        {9, 8},
        {14, 11}
      }
    })
  elseif chance(50) then -- thin algae
    merge_tables(s, {
      g = 0x19,
      w = 12 + rnd(12),
      h = 12 + rnd(12),
      a = a - 0.125,
      
      cols = pick{
        {15, 10},
        {16, 10},
        {10, 9},
        {9, 8},
        {14, 11}
      }
    })
  elseif chance(80) then -- coral
    merge_tables(s, {
      g = 0x26,
      w = 12 + rnd(12),
      h = 12 + rnd(12),
      a = a - 0.25,
      
      cols = pick{
        {15, 10},
        {16, 10},
        {14, 13},
        {13, 12},
        {20, 19},
        {22, 21},
        {23, 13},
        {21, 4}
      }
    })
  else -- clam
    local size = 12+rnd(8)
    merge_tables(s, {
      g = 0x32,
      w = size,
      h = size,
      a = a - 0.25,
      
      cols = pick{
        {19, 3},
        {27, 3},
      }
    })
  end
  
  if s.g ~= 0x19 and chance(50) then
    s.w = -s.w
  end
  
  add(algae, s)
end

function gen_algae()
  local step = 16

  for i = 96, length, step do
    if chance(75) then
      local y = min(flr(i + rnd(step)), length)
      
      local va = y - y % wall_step
      local vb = (y % wall_step) / wall_step
      local x = lerp(
        left_wall[va],
        left_wall[va + wall_step],
        vb
      )
      
      local ya, yb = va, va + wall_step
      local xa, xb = left_wall[ya], left_wall[yb]
      
      local a = atan2(xb-xa, yb-ya) + 0.25
      new_algae(x, y, a)
    end
  
    if chance(75) then
      local y = min(flr(i + rnd(step)), length)
      
      local va = y - y % wall_step
      local vb = (y % wall_step) / wall_step
      local x = lerp(
        right_wall[va],
        right_wall[va + wall_step],
        vb
      )
      
      local ya, yb = va, va + wall_step
      local xa, xb = right_wall[ya], right_wall[yb]
      
      local a = atan2(xb-xa, yb-ya) - 0.25
      new_algae(x, y, a)
    end
  end
  
  -- put some on bottom floor
  
end

function draw_algae()
  local t = 0.2 * t()

  for _,s in pairs(algae) do
    glyph(s.g, s.x, s.y, s.w, s.h, s.a + 0.05 * cos(t + s.t), s.cols[1], s.cols[2], 8, 14)
  end
end


function draw_surface()
  local y = surface_y
  local t = t()
  
  rectfill(-32, -32, screen_w()+32, y+8, 26)
  
  local bx = screen_w()/2
  local by = y + 8 * cos(0.5*t) * cos(bx/64 - 0.5*t)
  
  bezier(-16, -64, bx, by-8, 0, surface_y, 0.1, 0)
  
  outlined_glyph(0x18, bx+4, by-4, 16, 16, 0.05*cos(t), 29, 27, 0, 0, 16)
  outlined_glyph(0x07, bx, by, 16, 16, t, 21, 4, 0)
  
  for x = 0, screen_w()-1 do
    local y = y + 8 * cos(0.5*t) * cos(x/64 - 0.5*t)
    rectfill(x,y+2,x,y+16,17)
    rectfill(x,y,x,y+1,29)
    
    pset(x,y+18, 17)
  end
end



function gen_random_curve(n)
  n = n or 12

  local d,f = {}, 0.5
  for i = 1,n do
    add(d, {f = f, a = 0.01+rnd(4.99)/f, b = rnd(1)})
    f = f * 0.6
  end
  
  return d
end

function evaluate_curve(d, t)
  local v = 0
  for _,s in pairs(d) do
    v = v + s.f * cos(s.a * t + s.b)
  end
  
  return v
end



function bezier(xa,ya, xb,yb, xc,yc, step, c)
  color(c)
  
  local lx, ly = xa, ya
  
  for i = step, 1, step do
    local xac = lerp(xa, xc, i)
    local yac = lerp(ya, yc, i)
    
    local xcb = lerp(xc, xb, i)
    local ycb = lerp(yc, yb, i)
    
    local nx = lerp(xac, xcb, i)
    local ny = lerp(yac, ycb, i)
    
    line(lx, ly, nx, ny)
    lx, ly = nx, ny
  end
  
  line(lx, ly, xb, yb)
end

function foreach(ar, foo, ...)
  for _,el in ipairs(ar) do
    foo(el, ...)
  end
end

function dotimes(n, foo, ...)
  for i = 1,n do
    foo(...)
  end
end

function chance(n) return rnd(100) < n end
function give_or_take(n) return rnd(n*2)-n end
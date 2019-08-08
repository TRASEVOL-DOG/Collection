-- yet another maze

require("framework/framework")

_title = "Candy Hunt"

_description = "Looks like somebody is dropping candies in that maze, quick get them !"

_palette = { [0] = 0, 11, 7, 29, 20, 4, 21, 17, 26, 19}

_player_glyph =  0

_controls = {
  [ "left" ] = "Move",
  [ "up" ] = "Move",
  [ "right" ] = "Move",
  [ "down" ] = "Move",
}

_score = 0

maze = {}
candies = {}

displayed_maze = {}
old_maze = {}
new_maze = {}

smoke = {}
stars = {}

bg_glyphs = {}
bg_timer = 0

bggcp = {
  { 8, 1 },
  { 3, 1 },
  { 2, 1 },
  { 5, 2 },
  { 18, 3 },
  { 19, 5 },
  { 6, 5 },
  { 9, 8 },
  { 4, 5 },
}



function _init(difficulty)

  GW = screen_w()
  GH = screen_h()

  gl = {
    beer_pump = 0x60,
  }
  
  -- difficulty = difficulty or irnd(100) + 1
  difficulty = 100
  
  max_time = 45 - 38 * difficulty/100
  time_left = max_time
  p_per_g = (10 + 30 * difficulty/100) / 2
  
  maze_size = flr(9 + 6 * difficulty/100)
  
  s = 8
  p = 10
  w = 1
  
  maze_x = GW / 2 - p * maze_size / 2
  maze_y = GH / 2 - p * maze_size / 2 + 16
  
  for i = 1, 4 do
    add(candies, new_candy())
  end
  
  time_since_launch = 0
  time_between_m_g = 6 - 3 * difficulty/100
  
  displayed_maze_maze = copy_table(init_maze())
  new_maze = copy_table(init_maze())
  change_maze(init_maze())
  init_player()
  init_bg_glyphs()
  
end

function new_candy()
  local done = false
  while not done do
    local i = random_index()
    if not is_in(i, candies) then
      return {i = i, g = irnd(2)}
    end
  end
end

function change_maze(maze)
  old_maze = copy_table(new_maze)
  new_maze = copy_table(maze)
  displayed_maze = copy_table(old_maze)
  
  changing = true
  timer_change = 0
  max_time_change = time_between_m_g
  last_percentage = 0
end

function _update()
  time_left = time_left - dt()
  
  if time_left <= dt() then gameover(_score) end
  
  time_since_launch = time_since_launch + dt()
  
  if time_since_launch > time_between_m_g then
    time_since_launch = 0
    local i = flr((player.x - maze_x) / p) + 1
    local j = flr((player.y - maze_y) / p) + 1
    change_maze(init_maze(index(i,j)))
    screenshake(15)
  end
  
  if changing then
    timer_change = timer_change + dt()
    
    local ratio = timer_change / time_between_m_g
    local next_p = flr(#new_maze/maze_size*ratio)
    
    if next_p > last_percentage then
      for i = last_percentage , next_p - 1 do
        for j = 1, maze_size do
          local c = i * maze_size + j
          displayed_maze[c] = new_maze[c]
          local sx = ((c-1) % maze_size) * p
          local sy = flr((c-1) / maze_size) * p
          sx  = maze_x + sx + 4 + 1
          sy  = maze_y + sy + 4 + 1
          
          new_smoke(sx, sy + 5)
        end
      last_percentage = next_p
      end
    end
    
    if timer_change > time_between_m_g then
      changing = false
    end
  end
  
  update_bg()
  
  update_player()
  
  update_stars()
  update_smoke()
  
end

function new_smoke(x, y)
  for i = 1, 3 do
    add(smoke, {x = x - 2 + irnd(5) , y = y - 2 + irnd(5), r = 2 + irnd(5) })
  end
end

function update_smoke()
  for i, s in pairs(smoke) do 
    s.r = s.r - dt() * 10
    s.x = s.x + (irnd(3) - 1) * dt() * 9
    s.y = s.y - 1 * dt() * 30
    if s.r < 1 then del_at(smoke, i) end
  end
end

function draw_smoke()
  for i, s in pairs(smoke) do 
    circfill(s.x, s.y, s.r, _palette[0])
  end
end

function new_stars(x, y)
  for i = 1, 12 do
    add(stars, {x = x - 2 + irnd(5), y = y - 2 + irnd(5), vx =  - 2 + rnd(4) * 2, vy = -45 - irnd(45) })
  end
end

function update_stars()
  for i, s in pairs(stars) do 
    s.vy = s.vy + dt() * 300
    s.x = s.x + s.vx * dt() * 9
    s.y = s.y + s.vy * dt()
    if s.vy >30 then del_at(stars, i) end
  end
end

function draw_stars()
  for i, s in pairs(stars) do 
    rf(s.x , s.y, 1, 1, _palette[3])
  end
end

function _draw()  
  draw_bg()
  draw_maze()  
  draw_player()
  draw_stars()
  draw_smoke()
end

function update_bg()
  update_bg_glyphs()
end 

function draw_bg()
  cls(_palette[3])
  
  draw_bg_glyphs()
  
  printp(0x3330, 0x3130, 0x3230, 0x3330)
  printp_color(17, 18, 3) 
  
  local size = time_left / max_time * GW * 4/5
  
  rf( GW/2 - GW * 4.1/5 / 2 , 18, GW * 4.1/5, 12, 0)
  rf( GW/2 - size / 2, 20, size, 8, _palette[4])
  
  for j = - 8, GH + 8 do
    for i = - 8, GW + 8 do
      if (i%3 == 0) and (j % 3 == 0) then
        pset(i, 1 + j, 0)
      end
    end
  end
  
  local str = "TIME LEFT "
  local w = str_px_width(str)
  pprint(str , GW/2 - w/2 - 1, 0)
end

function init_bg_glyphs(timer)
  bg_glyphs = {}
  bg_timer = timer or 0
  bggcp = {
    { 8, 1 },
    { 3, 1 },
    { 2, 1 },
    { 5, 2 },
    { 18, 3 },
    { 19, 5 },
    { 6, 5 },
    { 9, 8 },
    { 4, 5 },
  }

  for i = 1, #bggcp do add( bg_glyphs, {}) end
end

function new_bg_g()
  local g = {spr = irnd(4),x = irnd(GW), y = GH + 32, a = rnd(1), r_speed = (irnd(2) - 0.5) * (0.1 + rnd(2.4)) }
  g.d = 1 + irnd(#bggcp)
  g.size = 16 + g.d * 2
  g.vspeed =  16 + ((6 + rnd(5)) * (g.d/ #bggcp))
  add( bg_glyphs[g.d], g)
end

function update_bg_glyphs()
  bg_timer = bg_timer - dt()
  if bg_timer < 0 then
    new_bg_g()
    bg_timer = .65 + rnd(.5)
  end
  for i = 1, #bg_glyphs do
    for j, g in pairs(bg_glyphs[i]) do
    g.y = g.y - g.vspeed * dt()
    g.a = g.a + g.r_speed * dt() / 10
    if g.y < -32 then del_at(bg_glyphs[i], j) end
    end
  end
end

function draw_bg_glyphs()
  for i = 1, #bg_glyphs do
    for j, g in pairs(bg_glyphs[i]) do
      outlined_glyph(0x62 + g.spr,  g.x + 3, g.y + 3, g.size, g.size, g.a, 0, 0, 0)
      outlined_glyph(0x62 + g.spr,  g.x, g.y, g.size, g.size, g.a, bggcp[g.d][1], bggcp[g.d][2], 0)
    end    
  end    
end

function rf(x, y, w, h, col)
  rectfill( x, y, x + w, y + h, col)
end

function random_index()
  return 1 + irnd(maze_size * maze_size)
end

player = {}

function init_player()
  local i = random_index()
  local sx = ((i-1) % maze_size) * p
  local sy = flr((i-1) / maze_size) * p
  player.x  = maze_x + sx + 4 + 1
  player.y  = maze_y + sy + 4 + 1
  player.vx = 0
  player.vy = 0
  
end

function update_player()

  local i = flr((player.x - maze_x) / p) + 1
  local j = flr((player.y - maze_y) / p) + 1
  
  local c = displayed_maze[index(i,j)]
      
  if btnp("up") and not c.walls[1] then 
    player.y = player.y - p
    screenshake(2)  
  end
  if btnp("right") and not c.walls[2] then 
    player.x = player.x + p
    screenshake(2)
  end
  if btnp("down") and not c.walls[3] then 
    player.y = player.y + p
    screenshake(2)
  end
  if btnp("left") and not c.walls[4] then 
    player.x = player.x - p  
    screenshake(2)
  end
    
  local i = flr((player.x - maze_x) / p) + 1
  local j = flr((player.y - maze_y) / p) + 1
  local id_p = index(i, j)
  
  for i, ci in pairs(candies) do
    local c = ci.i
    local fx = 1 + ((c-1) % maze_size)
    local fy = 1 + flr((c-1) / maze_size)
    local id_f = index(fx, fy)
    
    if (id_f == id_p) then
      score(i)
    end
  end
  
end

function score(i)
  screenshake(5)
  candies[i] = new_candy()
  _score = _score + p_per_g
    
  local i = flr((player.x - maze_x) / p) + 1
  local j = flr((player.y - maze_y) / p) + 1
  local c = index(i, j)
  
  local sx = ((c-1) % maze_size) * p
  local sy = flr((c-1) / maze_size) * p
  sx  = maze_x + sx + 4 + 1
  sy  = maze_y + sy + 4 + 1
  
  new_stars(sx, sy + 5)
end

function draw_player()

  local colr = flr(time_left * 8) % 2 == 0 and 5 or 3
  color(_palette[colr])
  circfill(player.x, player.y, 2)
end

function draw_maze()
  
  local s = 8
  local m = 1
  local p = 10
  w = s + m*2
  
  rf(maze_x, maze_y, w * maze_size, w * maze_size, _palette[1])
  
  for j = 1, maze_size do 
    for i = 1, maze_size do
      local x = maze_x + (i-1) * w 
      local y = maze_y + (j-1) * w
      local c = displayed_maze[index(i,j)]
      if c.walls[1] then rf(x,         y,         w, 1, _palette[2]) end
      if c.walls[2] then rf(x + w - 1, y,         1, w, _palette[2]) end
      if c.walls[3] then rf(x,         y + w - 1, w, 1, _palette[2]) end
      if c.walls[4] then rf(x,         y,         1, w, _palette[2]) end
    end  
  end
  
  color(_palette[3])
  for i, ci in pairs(candies) do
    local goal = ci.i
    local fx = ((goal-1) % maze_size) * w
    local fy = flr((goal-1) / maze_size) * w
    outlined_glyph(0x62 + ci.g, maze_x + fx + 6, maze_y + fy + 6 + sin(t()) * 2 , 6, 6, 0, _palette[3], _palette[4], 0)
  end
  
end


do   ------ MAZE generation

  function index(i, j)
    if i < 1 or i > maze_size or j < 1 or j > maze_size then return -1 end
    return i + (j-1) * maze_size   
  end

  function init_maze(i)
    
    local maze = {}
    
    for j = 1, maze_size do    
      for i = 1, maze_size do
        add(maze, {n = {}, walls = {true, true, true, true} , visited = false} ) 
      end
    end
    
    for j = 1, maze_size do    
      for i = 1, maze_size do
        local ns = {}
        local t = index(i, j-1)
        local r = index(i+1, j)
        local b = index(i, j+1)      
        local l = index(i-1, j)
        
        if t and maze[t] then add(ns, t) end
        if r and maze[r] then add(ns, r) end
        if b and maze[b] then add(ns, b) end
        if l and maze[l] then add(ns, l) end
        ns = shuffle(ns)      
        maze[index(i,j)].n = ns
      end  
    end    
    visit(maze, 1 + irnd(maze_size * maze_size)) 
    return maze
  end

  function shuffle(tab)
    local new_tab = {}
    new_tab = copy_table(tab)
    for i = 1, 20 do
      local a = 1 + irnd(#new_tab)
      local b = 1 + irnd(#new_tab)    
      local d = new_tab[a]
      new_tab[a] = new_tab[b]
      new_tab[b] = d    
    end
    return new_tab
  end

  function visit(maze, index)
    if not index or index == -1 then return end
    local current = maze[index]
    current.visited = true
    
    for i, n in pairs(current.n) do
      if not maze[n].visited and i ~= index then
      
        local nx = maze[n]
        local diff = n - index      
        if diff == maze_size then      
          current.walls[3] = false
          nx.walls[1] = false
          
        elseif diff == -1 then
          current.walls[4] = false
          nx.walls[2] = false
          
        elseif diff == - maze_size then
          current.walls[1] = false
          nx.walls[3] = false
          
        elseif diff == 1 then
          current.walls[2] = false
          nx.walls[4] = false
        end
        visit(maze,n)      
      end  
    end
  end
end

function is_in(value, tab)  
  if not tab then return end
  for i, v in pairs(tab) do
    if value == v then return i end
  end
end













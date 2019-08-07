-- yet another maze

require("framework/framework")

_title = "Candy Hunt"

_description = "Looks like somebody is dropping candies in that maze, quick get them !"

_palette = { [0] = 0, 11, 7, 29, 20, 4, 21, 17, 26, 19}

_player_glyph =  0

_controls = {
  [ "cur_lb" ] = "Action",
}

_score = 0

maze = {}
candies = {}

function _init(difficulty)

  GW = screen_w()
  GH = screen_h()

  gl = {
    beer_pump = 0x60,
  }
  
  -- difficulty = difficulty or irnd(100)
  difficulty = 100
  
  time_left = 45 - 38 * difficulty/100
  p_per_g = (10 + 90 * difficulty/100) / 2
  
  maze_size = flr(9 + 6 * difficulty/100)
  
  s = 8
  p = 10
  w = 1
  
  maze_x = GW / 2 - p * maze_size / 2
  maze_y = GH / 2 - p * maze_size / 2
  
  for i = 1, 4 do
    add(candies, new_candy())
  end
  
  time_since_launch = 0
  time_between_m_g = 5 - 3 * difficulty/100
  
  init_maze()
  init_player()


end

function new_candy()
  local done = false
  while not done do
    local i = random_index()
    if not is_in(i, candies) then
      return i
    end
  end
end

function _update()

  time_since_launch = time_since_launch + dt()
  if time_since_launch > time_between_m_g then
    time_since_launch = 0
    local i = flr((player.x - maze_x) / p) + 1
    local j = flr((player.y - maze_y) / p) + 1
    init_maze(index(i,j))
    screenshake(15)
  end
  
  update_player()

end

function _draw()  
  draw_bg()
  draw_maze()  
  draw_player()
end

function draw_bg()
  cls(_palette[0])
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
  
  local c = maze[index(i,j)]
      
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
  
  for i, c in pairs(candies) do 
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
  
end

function draw_player()

  local colr = 5
  color(_palette[colr])
  circfill(player.x, player.y, 2)
end

function draw_maze()
  
  local s = 8
  local m = 1
  local p = 10
  local w = s + m*2
  
  -- rf(maze_x, maze_y, p * maze_size, p * maze_size, _palette[1])
  
  -- color(_palette[3])
  -- for i, goal in pairs(candies) do
    -- local fx = ((goal-1) % maze_size) * p
    -- local fy = flr((goal-1) / maze_size) * p
    -- circfill(maze_x + fx + p/2 , maze_y + fy + p/2 + 1, 3)
  -- end
  -- for j = 1, maze_size do 
    -- for i = 1, maze_size do
      -- local x = (i-1) * p 
      -- local y = (j-1) * p
      -- local c = maze[index(i,j)]
      -- if c.walls[1] then rf(maze_x + x,     maze_y + y,      p,- w, _palette[2]) end
      -- if c.walls[2] then rf(maze_x + x + p, maze_y + y,      w,  p, _palette[2]) end
      -- if c.walls[3] then rf(maze_x + x,     maze_y + y + p,  p,  w, _palette[2]) end
      -- if c.walls[4] then rf(maze_x + x,     maze_y + y,     -w,  p, _palette[2]) end
    -- end  
  -- end
  
  rf(maze_x, maze_y, w * maze_size, w * maze_size, _palette[1])
  
  color(_palette[3])
  for i, goal in pairs(candies) do
    local fx = ((goal-1) % maze_size) * w
    local fy = flr((goal-1) / maze_size) * w
    circfill(maze_x + fx + w/2 , maze_y + fy + w/2 + 1, 3)
  end
  
  for j = 1, maze_size do 
    for i = 1, maze_size do
      local x = maze_x + (i-1) * w 
      local y = maze_y + (j-1) * w
      local c = maze[index(i,j)]
      if c.walls[1] then rf(x,         y,         w, 1, _palette[2]) end
      if c.walls[2] then rf(x + w - 1, y,         1, w, _palette[2]) end
      if c.walls[3] then rf(x,         y + w - 1, w, 1, _palette[2]) end
      if c.walls[4] then rf(x,         y,         1, w, _palette[2]) end
    end  
  end
  
  
  
end


do   ------ MAZE generation

  function index(i, j)
    if i < 1 or i > maze_size or j < 1 or j > maze_size then return -1 end
    return i + (j-1) * maze_size   
  end

  function init_maze(i)
    
    maze = {}
    
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
    
    visit(1 + irnd(maze_size * maze_size)) 
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

  function visitable_neighbors(index)
    local ct_visitable = 0
    for i, n in pairs(maze[index].n) do
      if not maze[n].visited then ct_visitable = ct_visitable + 1 end
    end
  end

  function visitable_cells()
    for i, n in pairs(maze) do
      if not n.visited then return true end
    end  
  end

  function visit(index)
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
        visit(n)      
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













-- yet another maze

require("framework/framework")

_title = "Maze out"

_description = "It's summer, and people are really thirsty."

_palette = { [0] = 0, 11, 7, 29, 20, 4, 21, 17, 26, 19}

_player_glyph =  0

_controls = {
  [ "cur_lb" ] = "Action",
}

maze = {}

function _init(difficulty)

  GW = screen_w()
  GH = screen_h()

  gl = {
    beer_pump = 0x60,
  }
  
  maze_size = 15
  
  s = 8
  p = 10
  w = 1
  
  maze_x = GW / 2 - p * maze_size / 2
  maze_y = GH / 2 - p * maze_size / 2
  
  init_maze()
  init_player()

  start  = 1 + irnd(2) *(maze_size - 1)
  finish = 1 + maze_size * (maze_size - 1) + irnd(2) *(maze_size - 1)

end

function _update()

  time_since_launch = time_since_launch + dt()
  if time_since_launch > time_between_m_g then
    time_since_launch = 0
    init_maze()
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


player = {}

function init_player()
  player.x  = maze_x + 4 + 1
  player.y  = maze_y + 4 + 1
  player.vx = 0
  player.vy = 0
  
end

function update_player()

  local i = flr((player.x - maze_x) / p) + 1
  local j = flr((player.y - maze_y) / p) + 1
    
  local c = maze[index(i,j)]
  
  if btnp("up") and not c.walls[1] then 
    player.y = player.y - p
    
  end
  if btnp("right") and not c.walls[2] then 
    player.x = player.x + p
    
  end
  if btnp("down") and not c.walls[3] then 
    player.y = player.y + p
    
  end
  if btnp("left") and not c.walls[4] then 
    player.x = player.x - p  
  end
       
end

function draw_player()

  local sx = 1 + ((start-1) % maze_size)
  local sy = 1 + flr((start-1) / maze_size)
  
  local fx = 1 + ((finish-1) % maze_size)
  local fy = 1 + flr((finish-1) / maze_size)
  
  local i = flr((player.x - maze_x) / p) + 1
  local j = flr((player.y - maze_y) / p) + 1
  
  local id_s = index(sx, sy)
  -- log(id_s)
  local id_f = index(fx, fy)
  -- log(id_f)
  local id_p = index(i, j)
  -- log(id_p)
  
  local colr = ((id_s == id_p) or (id_f == id_p)) and 4 or 5
  -- log(colr)
  color(_palette[colr])
  circfill(player.x, player.y, 2)
end

function draw_maze()
  
  local s = 8
  local p = 10
  local w = 1
  
  rf(maze_x, maze_y, p * maze_size, p * maze_size, _palette[1])

  for j = 1, maze_size do 
    for i = 1, maze_size do
      local x = (i-1) * p 
      local y = (j-1) * p
      local c = maze[index(i,j)]
      if c.walls[1] then rf(maze_x + x,     maze_y + y,      p,- w, _palette[2]) end
      if c.walls[2] then rf(maze_x + x + p, maze_y + y,      w,  p, _palette[2]) end
      if c.walls[3] then rf(maze_x + x,     maze_y + y + p,  p,  w, _palette[2]) end
      if c.walls[4] then rf(maze_x + x,     maze_y + y,     -w,  p, _palette[2]) end
      
    end  
  end
  
  local sx = ((start-1) % maze_size) * p
  local sy = flr((start-1) / maze_size) * p
  rf(maze_x + sx, maze_y + sy, p, p)
  
  local fx = ((finish-1) % maze_size) * p
  local fy = flr((finish-1) / maze_size) * p
  rf(maze_x + fx, maze_y + fy, p, p)
  
  
end


do   ------ MAZE generation

  function index(i, j)
    if i < 1 or i > maze_size or j < 1 or j > maze_size then return -1 end
    return i + (j-1) * maze_size   
  end

  function init_maze()

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
    time_since_launch = 0
    time_between_m_g = 3
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















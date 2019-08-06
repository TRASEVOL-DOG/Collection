-- yet another maze

require("framework/framework")

_title = "Maze out"

_description = "It's summer, and people are really thirsty."

_palette = { [0] = 0, 11, 7, 29, 20, 4, 21, 17, 26, 19}

_player_glyph =  

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
  
  maze_size = 10

  init_maze()

end

function index(i, j)
  if i < 1 or i > maze_size or j < 1 or j > maze_size then return -1 end
  
  return i + j * maze_size 
  
end

function init_maze()
  
  for j = 1, maze_size do    
    for i = 1, maze_size do
      local walls = {true, true, true, true}
      local ns = {}
      local t = index(i, j-1)
      local r = index(i+1, j)
      local b = index(i, j+1)      
      local l = index(i-1, j)
      
      if t and maze[t] then add(ns, t) end
      if r and maze[r] then add(ns, r) end
      if b and maze[b] then add(ns, b) end
      if l and maze[l] then add(ns, l) end
      
      add(maze, {n = ns, walls = walls, visited = false ) 
    end  
  end  
  
  visit(1)  
  
end

function visit(index)
  if not maze[index] then return end
  
  local c = maze[index] -- current
  
  local n = 1 + irnd(c.n)
  local nxt = c.n[n]
  local nx  = maze[c.n[n]]
  
  while nx.visited do 
    n = 1 + irnd(c.n)
    nxt = c.n[n]
    nx  = maze[c.n[n]]
  end
  
  local diff = index - nxt
  
  if diff == maze_size then
    -- nxt top
    c.walls[1] = false
    nx.walls[3] = false
  elseif diff == 1 then
    -- nxt right
    c.walls[2] = false
    nx.walls[4] = false
  elseif diff == - maze_size then
    -- nxt bottom
    c.walls[3] = false
    nx.walls[1] = false
  elseif diff == -1
    -- nxt left
    c.walls[4] = false
    nx.walls[2] = false
  else
    log("can't visit cause diff = " .. diff )
  end

  c.visited = true
  visit(nxt)

end

function _update()

end

function _draw()
  cls(_palette[0])
end




















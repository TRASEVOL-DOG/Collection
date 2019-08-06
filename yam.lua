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
  
  maze_size = 9

  init_maze()

end

function index(i, j)
  if i < 1 or i > maze_size or j < 1 or j > maze_size then return -1 end
  return i + (j-1) * maze_size   
end

function init_maze()
  
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
  
  visit(1) 
  
  -- for j = 1, maze_size do    
    -- for i = 1, maze_size do
      -- local c = maze[index(i,j)]
      -- log("walls for i : " .. i .. " and j : " .. j )
      -- log("top : "    .. (c.walls[1] and "yes" or "no" ))
      -- log("right : "  .. (c.walls[2] and "yes" or "no" ))
      -- log("bottom : " .. (c.walls[3] and "yes" or "no" ))
      -- log("left : "   .. (c.walls[4] and "yes" or "no" ))
    -- end
  -- end
  
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
  -- log("visit index : " .. (index and index or "nil") )
  if not index or index == -1 then return end
  local current = maze[index]
  current.visited = true
  
  -- for i, n in pairs(current.n) do
    -- log("a neighbor is " .. n)
  -- end
  
  for i, n in pairs(current.n) do
    -- log("n = " .. n)
    -- log((maze[n].visited and "already visited" or "free"))
    if not maze[n].visited and i ~= index then
      -- log("index = " .. index .. " and n = " .. n )
    
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
        
      else
        -- log("can't visit cause diff = " .. diff )
      end
      -- log("here")
      visit(n)      
    end  
  end
end

function _update()

end

function rf(x, y, w, h, col)
  rectfill( x, y, x + w, y + h, col)
end

function _draw()
  cls(_palette[0])
  
  local s = 8
  local p = 10
  local w = 1
  
  rf(p, p, p * maze_size, p * maze_size, _palette[1])

  for j = 1, maze_size do 
    for i = 1, maze_size do
      local x = i * p
      local y = j * p
      local c = maze[index(i,j)]
      if c.walls[1] then rf(x,     y,      p,- w, _palette[2]) end
      if c.walls[2] then rf(x + p, y,      w,  p, _palette[2]) end
      if c.walls[3] then rf(x,     y + p,  p,  w, _palette[2]) end
      if c.walls[4] then rf(x,     y,     -w,  p, _palette[2]) end
      
    end  
  end

end


















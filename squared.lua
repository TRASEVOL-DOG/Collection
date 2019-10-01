require("framework/framework")

_title = "Square = Rectangle"

_description = "Someone wasn't okay with that, and broke it into pieces."

_player_glyph = 0x62

_controls = {
  [ "left" ] = "Move",
  [ "up" ] = "Move",
  [ "right" ] = "Move",
  [ "down" ] = "Move",
}

_score = 0

playground = {}

pieces = {}

function _init(difficulty)

  difficulty        = difficulty or irnd(100) + 1
  GW                = screen_w()
  GH                = screen_h()
  time_since_launch = 0
  
  init_palette()
  
  piece_cols_temp = {
    {_p_n("white"),_p_n("black")}, 
    {_p_n("black"),_p_n("white")},  
    
    {_p_n("red"),_p_n("dark_red")},  
    {_p_n("blue"),_p_n("dark_blue")},  
    {_p_n("yellow"),_p_n("dark_yellow")},  
  }
  
  piece_cols = copy_table(piece_cols_temp)
  
  init_camera()
  init_playground(13, 10)
  init_hud(difficulty)
  
    -- local c = rnd_p_c()
    -- add_piece(nil, nil, nil, 1, c[1], c[2])
    -- c = rnd_p_c()
    -- add_piece(nil, nil, nil, 2, c[1], c[2])
  
end

function rnd_p_c()
  local i = 1 + irnd(#piece_cols)
  local c = copy_table(piece_cols[i])
  del_at(piece_cols, i)
  return c

end

function _update()
  time_since_launch = time_since_launch + dt()
  
  update_playground()
  update_hud()
  update_camera()
end

function _draw()  
	draw_background()
	draw_playground()
  draw_hud()
end

--XXXXXXXXX CAMERA XXXXXXXXX

function init_camera()
  world = {}
  world.w = GW*1.5
  world.h = GH*1.5
  
  cam = {}  
  cam.x = world.w/2 - GW / 2
  cam.y = world.h/2 - GH / 2  
  
  -- cam.x = 0
  -- cam.y = 0  
  
  cam.x_speed = 16 * 8
  cam.y_speed = 16 * 8
  
end

function update_camera()
end

function move_camera(dir)
  if dir == "left"  then 
    cam.x = cam.x - cam.x_speed * dt()
    if cam.x < 0 then 
      cam.x = 0 
      return false
    end  
  end
  if dir == "right" then 
    cam.x = cam.x + cam.x_speed * dt()
    if cam.x > world.w/3 then 
      cam.x = world.w/3 
      return false
    end
  end
  if dir == "up"    then 
    cam.y = cam.y - cam.y_speed * dt()
    if cam.y < 0 then 
      cam.y = 0
      return false 
    end
  end 
  if dir == "down"  then 
    cam.y = cam.y + cam.y_speed * dt()
    if cam.y > world.h/3 then 
      cam.y = world.h/3
      return false 
    end
  end
  return true
end


--XXXXXXXXX HUD XXXXXXXXX

function init_hud()
  init_chrono(difficulty)
  init_cursor()
end

function update_hud()
  update_chrono()
  update_cursor()
end

function draw_hud()
	draw_chrono()  
  draw_cursor()
end

function draw_background()
	cls(_p_n("bg"))
end

  --XXXXXXXXX CURSOR XXXXXXXXX
  function init_cursor()
    cursor = {}
    
    cursor.x = GW / 2
    cursor.y = GH / 2
    cursor.w = 8
    cursor.h = 8
    cursor.g = 0
    
    -- previous_m_x = 0
    -- previous_m_y = 0
    x_axis = 0
    y_axis = 0
    
  end
  
  function update_cursor()
    
    local dz = 32
    if btn("left") or x_axis < 0 then 
      if cursor.x > dz then 
        cursor.x = cursor.x - cam.x_speed * dt()      
      else
        if move_camera("left") then
          cursor.x = dz
        else
          cursor.x = cursor.x - cam.x_speed * dt() 
          if cursor.x < 0 then cursor.x = 0 end
        end
      end
      mouse_mvd = (x_axis ~= 0) or (y_axis ~= 0)
    end
    
    if btn("right") or x_axis > 0 then 
      if cursor.x < GW - 20 - dz - cursor.w then 
        cursor.x = cursor.x + cam.x_speed * dt()      
      else
        if move_camera("right") then
          cursor.x =  GW - 20 - dz - cursor.w
        else
          cursor.x = cursor.x + cam.x_speed * dt() 
          if cursor.x > GW - 20 - cursor.w then cursor.x = GW - 20 - cursor.w end
        end
      end
      mouse_mvd = (x_axis ~= 0) or (y_axis ~= 0)
    end
    
    if btn("up") or y_axis < 0 then 
      if cursor.y > dz then 
        cursor.y = cursor.y - cam.y_speed * dt()      
      else
        if move_camera("up") then
          cursor.y = dz
        else
          cursor.y = cursor.y - cam.y_speed * dt() 
          if cursor.y < 0 then cursor.y = 0 end
        end
      end
      mouse_mvd = (x_axis ~= 0) or (y_axis ~= 0)
    end
    
    if btn("down") or y_axis > 0 then 
      if cursor.y < GH - cursor.h - dz then 
        cursor.y = cursor.y + cam.y_speed * dt()      
      else
        if move_camera("down") then
          cursor.y =  GH - cursor.h - dz
        else
          cursor.y = cursor.y + cam.y_speed * dt() 
          if cursor.y > GH - cursor.h then cursor.y = GH - cursor.h end
        end
      end
      mouse_mvd = (x_axis ~= 0) or (y_axis ~= 0)
    end

  end
  
  function cursor_on_piece(p, xx, yy)
  
    for j, line in pairs(p.lines) do
      local y = p.y + j*8
      for i, s in pairs(line) do
        local x = p.x + i*8
        if s == 1 then 
          if point_in_rect( x, y, x + 8, y + 8, xx, yy) then
            return true 
          end
        end
      end
    end
  
  end
  
  function draw_cursor()
    outlined_glyph(cursor.g, cursor.x, cursor.y, cursor.w, cursor.h, 0, _p_n("white"), _p_n("white"), 0)
  end
  
  --XXXXXXXXX CHRONO XXXXXXXXX

  function init_chrono(difficulty)
    time_accorded = 20
    time_left = time_accorded
    sectors = 8
    
    chrono = {}  
    chrono.w = 16
    chrono.h = GH - 32  
    chrono.x = GW - chrono.w - 4
    chrono.y = GH - (GH/2 - chrono.h/2)
    
  end

  function update_chrono()
    time_left = time_left - dt()
    
    -- if btnp("B") then
      -- log(time_accorded - time_left)
    -- end
  end

  function draw_chrono()

    rf(chrono.x - 4, 0, chrono.w * 1.5, GH, _p_n("bg"))
    rf(chrono.x - 4, 0, 0, GH, 0)
        
    local ratio = max(0, time_left) / time_accorded * sectors  
    ratio = ceil(ratio) / sectors  
    if ratio > 0 then
      rf(chrono.x, chrono.y, chrono.w, - chrono.h * ratio, 0)
    end
    
  end
  --XXXXXXXXXXXXXXXXXX


--XXXXXXXXX PLAYGROUND XXXXXXXXX

function init_playground(w, h)
  
  init_puzzle(w, h)
	playground = {}
	local p = playground
	
	p.pixel_d = 8
	p.w  = w or 10
	p.h = h or 10  
	p.rw = p.w * p.pixel_d
	p.rh = p.h * p.pixel_d  
	p.x = world.w/2 - p.rw/2 - 8
	p.y = world.h/2 - p.rh/2
  
  p.x = p.x - (p.x%8)
  p.y = p.y - (p.y%8)
  
  init_pieces_coord()
  
end

function update_playground()
  update_pieces()
end

function draw_playground()  
	local p = playground or {} 
  
  local x = p.x - 3 - cam.x
  local y = p.y - 3 - cam.y
  
  rf(x, y, p.rw + 6, p.rh + 6, _p_n("white")) 
  
  local x = p.x - cam.x
  local y = p.y - cam.y 
  
  rf(x, y, p.rw, p.rh, _p_n("black"))   
  
  
  draw_pieces()

end

--XXXXXXXXX PIECES XXXXXXXXX

function init_pieces_coord()

  local p = playground
  local step = 1/#pieces
  local a = 0
  for i, pi in pairs(pieces) do
    local x = p.x + p.rw/4
    local y = p.y + p.rh/4
    
    x = x + cos(a) * p.rw
    y = y + sin(a) * p.rw
            
    pi.x = x - (x%8) -- GRID
    pi.y = y - (y%8) -- GRID
    a = a + step
  end
end

function add_piece(x, y, lines, num, c1, c2)

  count = (count or 0) + 1
  
  add(pieces,{  
    x = x or irnd(4) * 8,
    y = y or irnd(4) * 8,  
    lines = lines or rnd_p(4, 4),
    num = count,   
    primary   = c1 or _p_n("white"),
    secondary = c2 or _p_n("black"),
  })  
  -- local p = pieces[#pieces].lines
  -- log("Created piece: \n" ..
      -- "w = .." .. #p[1] .. "\n" ..
      -- "h = .." .. #p .. "\n"
      -- "h = .." .. #piece[1] .. "\n" ..
      -- )
end

function rnd_p(width, height)
  local ls = {}
  
  for j = 1, height do 
    local l = {}
    for i = 1, width do 
      add(l, irnd(2))
    end
    add(ls, l)
  end  
  return ls  
end

function update_pieces()
  
  if not selected then
    for i, p in pairs(pieces) do
      if cursor_on_piece(p, cursor.x + cam.x, cursor.y + cam.y) then
        if btnp("A") then
          put_piece_on_top(i)    
          x_offset = p.x - (cursor.x + cam.x)
          y_offset = p.y - (cursor.y + cam.y)
          selected = true
          break 
        end
      end
    end
  else  
    
    local p = pieces[#pieces]
    p.x = cursor.x + x_offset + cam.x
    p.x = p.x - (p.x%8) -- GRID
    
    p.y = cursor.y + y_offset + cam.y
    p.y = p.y - (p.y%8) -- GRID
    if btnp("A") then
      selected = nil
    end
  end
  
  -- for i, p in pairs(pieces) do 
    -- update_piece(p)  
  -- end
  
end

function draw_pieces()
  for i, p in pairs(pieces) do 
    draw_piece(p)  
  end
end

function update_piece(p)
end

function put_piece_on_top(id_p)
  swap(pieces, #pieces, id_p)
end

function swap(t, id1, id2)
  local temp
  temp = t[id1]
  t[id1] = t[id2]
  t[id2] = temp
end

function draw_piece(p)
  for j, line in pairs(p.lines) do
    local o = p.selected and -2 or 0
    local y = p.y + j*8 - cam.y + o
    for i, s in pairs(line) do
      local x = p.x + i*8 - cam.x + o
      if s == 1 then
        rf(x, y, 8, 8, p.secondary) 
        rf(x+1, y+1, 6, 6, p.primary) 
      end
    end
  end
end

--XXXXXXXXX MISC XXXXXXXXX


function rf(x, y, w, h, col)
  rectfill( x, y, x + w-1, y + h-1, col)
end

function is_in(value, tab)  
  if not tab then return end
  for i, v in pairs(tab) do
    if value == v then return i end
  end
end

function init_palette()
	_palette = {
		{name = "bg",    col = 3},
		{name = "black", col = 0},
		{name = "white", col = 29},
    
		{name = "red", col = 21},
		{name = "dark_red", col = 5},
		{name = "blue", col = 17},
		{name = "dark_blue", col = 18}, -- 18 or 3
		{name = "yellow", col = 14},
		{name = "dark_yellow", col = 11},
	}
end

function _p_i(index)
	if _palette[index] then return _palette[index].col end
end

function _p_n(name)
  -- return 0
	for i, c in pairs(_palette) do
		if c.name == name then return c.col end
	end
end

function point_in_rect( x1, y1, x2, y2, px, py)
  if not x1 or not y1 or not x2 or not y2 then return end
  local px = px or 0
  local py = py or 0
  return px > x1 and px < x2 and py > y1 and py < y2
end

-- puzzle

function init_puzzle(w, h)
  puzzle = {}
  -- init_puzzle
  for j = 1, h do 
    local line = {}
    for i = 1, w do 
      add(line, 0)
    end
    add(puzzle, line)
  end
  
  for i = 1, 50 do
    add_rect_in_p(i%4 + 1, irnd(w - 3), irnd(h - 3), 4, 4)  
  end
  
  n_templates = {
    {-1, 0 },
    {0 ,-1},
    {1 ,0 },
    {0 ,1 },  
  }
  -- remove single cell in puzzle
  for j, l in pairs(puzzle) do
    for i, v in pairs(l) do
      local found = false
      local neighbor_v
      for _, n_t in pairs(n_templates) do 
      
        neighbor_v = ( puzzle[j + n_t[2]] and puzzle[j + n_t[2]][i + n_t[1]] ) or neighbor_v
        
        if neighbor_v then
          if neighbor_v == v then
            found = true
          end  
        end  
      end
      
      if not found then 
        log("found a single cell in x:" .. i .. " y:" .. j)
        log("old v = " .. puzzle[j][i])
        puzzle[j][i] = neighbor_v
        log("new v = " .. puzzle[j][i])
      end
      
    end
  end   
  
  copy_puzzle = copy(puzzle)
  
  to_visit = {}
  
  function add_cell_to_piece(x, y) 
    if not puzzle[y] or not puzzle[y][x] then return end 
    -- log("added " .. x .. "," .. y)
    piece = piece or {c = {}}
    add(piece.c, {x, y})    
    piece.v = puzzle[y][x]
    mark_cell(x,y)
  end
  
  function mark_cell(x,y)  
    puzzle[y][x] = -1     
    add(to_visit,{x, y})  
  end
  
  function is_puzzle_empty()
    if not puzzle then return true end  
    for i, l in pairs(puzzle) do
      for j, v in pairs(l) do
        if v ~= -1 then return false end
      end
    end    
    return true
  end
  
  function create_new_piece()
      if piece and piece.c and #piece.c > 0 then
        count = count or 0
        count = count + 1
        local min_x, min_y, max_x, max_y
        
        for id, cell in pairs(piece.c) do
          min_x = min_x or cell[1]
          max_x = max_x or cell[1]
          
          min_y = min_y or cell[2]          
          max_y = max_y or cell[2]
        
          if cell[1] < min_x then min_x = cell[1] end
          if cell[2] < min_y then min_y = cell[2] end
          
          if cell[1] > max_x then max_x = cell[1] end
          if cell[2] > max_y then max_y = cell[2] end
          
        end
        
        local w = max_x - min_x + 1
        local h = max_y - min_y + 1
        
        local new_p = {}
        
        for j = 1, h do 
          local line = {}
          for i = 1, w do 
            add(line, 0)
          end
          add(new_p, line)
        end
        
        for id, cell in pairs(piece.c) do
          cell[1] = cell[1] - min_x + 1
          cell[2] = cell[2] - min_y + 1
          new_p[cell[2]][cell[1]] = 1
        end
        -- log(piece.v)
        local col = piece_cols_temp[1 + piece.v]
        
        add_piece(nil, nil, new_p, nil, col[1], col[2] )  
        piece.c = {}
        
        
      end
      -- find coord of a cell not visited
      found = false
      if puzzle then
        for j, l in pairs(puzzle) do 
          for i, v  in pairs(l) do
            if not found then
              if v ~= -1 then
                found = true
                add_cell_to_piece(i, j)
              end               
            end
          end 
        end 
      end
      
    end  
  
  -- log(copy_puzzle[1][1])
  -- log("new piece!")
  while not is_puzzle_empty() do
    
    if #to_visit > 0 then
      cell = puzzle[ to_visit[1][2] ] and puzzle[ to_visit[1][2] ][ to_visit[1][1] ]
      -- go to all neighbors        
      for _, n_t in pairs(n_templates) do      
      
        local neighbor_x = to_visit[1][1] + n_t[1]
        local neighbor_y = to_visit[1][2] + n_t[2]        
        local n = puzzle[neighbor_y] and puzzle[neighbor_y][neighbor_x]
        
        if n and n == piece.v then
          add_cell_to_piece(neighbor_x, neighbor_y)       
        end          
      end     
      del_at(to_visit, 1)
    else 
      create_new_piece()
    end
  end
  create_new_piece()
  puzzle = copy(copy_puzzle)
end

function add_rect_in_p(v,x,y,w,h) 
  if not v then return end 
  for j = max(1,y) , min(#puzzle, y+h) do
    for i = max(1,x) , min(#puzzle[1], x+w) do
      puzzle[j][i] = v     
    end  
  end
end


function copy(obj)
  if type(obj) ~= 'table' then return obj end
  local res = {}
  for k, v in pairs(obj) do res[copy(k)] = copy(v) end
  return res
end















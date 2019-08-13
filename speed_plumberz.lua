require("framework/framework")

_title = "Speed PlumberZ"

_description = "Water flows, so does time !   From (S)tart to (F)inish!  "

_player_glyph = 0x4C

_palette = { ["0"] = 0, 8, 14, 13, 20, 4, 10, 15, 17, 29, 30}

_controls = {

  [ "cur_x"  ] = "Hover on piece you want to move!",
  [ "cur_y"  ] = "Hover on piece you want to move!",
  
  [ "A"      ] = "Release the water!",
  
  [ "cur_lb" ] = "Rotate pieces!",
  [ "cur_rb" ] = "Change angle ! (Blue pipes only)"
}

_score = 0

local GW, GH = 0, 0
local time_since_launch = 0
local t = function() return time_since_launch or 0 end

local time_per_piece = .5
local flow_anim_timer

local flow_incomming_from -- 1 for up, 2 for right, 3 for down, 4 for left
local flowing_path
local diff

function _init(difficulty)
  GW = screen_w()
  GH = screen_h()
  
  g_spr = {
    arrow  = 0x43,    
    flag   = 0x44,    
    pieces = {0x40, 0x41, 0x42, 0x43, 0x42, 0x43, 0x46, 0x47, 0x48, 0x49, 0x4D},    
    bubble = {0x4A, 0x4B},    
    water  = 0x4C,    
  }  
  diff = difficulty or (25 + irnd(75))    
    
  generate_path()
  way = working_path[1]
    g = working_path_to_full_grid(way)  
  level_completed = 0
  
  in_flow = false
  counter_on = true
  
  time_left = 120 - ceil(20 * (diff/100 * diff / 100) )
  t_l_b = time_left
  time_per_piece = .1
  flow_anim_timer = time_per_piece
  
end

local index = 1


function flow_to_(grid_id)
  local c = g[grid_id]
  if not c then return end
  local t = {grid_id - p_width, grid_id + 1, grid_id + p_width, grid_id - 1}
  if c.piece == 1 or c.piece == 2 then return {t[c.angle == .25 and 1 or c.angle == .5 and 2 or c.angle == .75 and 3 or 4]}
  elseif c.piece == 3 or c.piece == 5 then
    if     c.angle == 0   or c.angle == .5  then return {grid_id - 1, grid_id + 1} 
    elseif c.angle == .25 or c.angle == .75 then return {grid_id - p_width, grid_id + p_width} end
  elseif c.piece == 4 or c.piece == 6 then
    if     c.angle == 0   then return {grid_id + p_width, grid_id - 1}
    elseif c.angle == .25 then return {grid_id - 1, grid_id - p_width}
    elseif c.angle == .5  then return {grid_id - p_width, grid_id + 1}
    elseif c.angle == .75 then return {grid_id + 1, grid_id + p_width} end
  end
end

function flow_from_to( grid_p1, grid_p2)
  local from = flow_to_(grid_p1)
  local to = flow_to_(grid_p2)  
  if value_in(grid_p2, from) then 
    if value_in(grid_p1, to) then
      return true   
    end 
  end 
end

start_flow_direction = 2
end_flow_direction   = 4

function _update()

  time_since_launch = time_since_launch + dt()
  if counter_on then
    time_left = time_left - (dt() * (1 + diff/100 / 3))
    if time_left < 0 then gameover(_score, {"Time's up :(", "Better luck next time!"}) end
  else
    flow_anim_timer = flow_anim_timer - dt()
    screenshake(1)
    if flow_anim_timer < 0 then
      flow_anim_timer = time_per_piece
      local current_cell_id = flowing_path[#flowing_path]
      local current_cell    = g[current_cell_id]
      
      if current_cell_id == p_start then
        if current_cell.angle == 0 then
          if flow_from_to(p_start, p_start - 1) then
            flow_incomming_from = 2
            add(flowing_path, p_start - 1)
          end 
        elseif current_cell.angle == .25 then
          if flow_from_to(p_start, p_start - p_width) then
            flow_incomming_from = 3
            add(flowing_path, p_start - p_width)
          end 
        elseif current_cell.angle == .5 then
          if flow_from_to(p_start, p_start + 1) then
            flow_incomming_from = 4
            add(flowing_path, p_start + 1)
          end
        elseif current_cell.angle == .75 then
          if flow_from_to(p_start, p_start + p_width) then
            flow_incomming_from = 1
            add(flowing_path, p_start + p_width)
          end    
        end 
        
        if current_cell_id == flowing_path[#flowing_path] then counter_on = true end    
        
      elseif current_cell_id == p_end then 
        -- counter_on = true
        give_points(mid(0, time_left, 100))
        gameover(_score, {"","You took " .. ceil(t_l_b - time_left) .. " seconds !", "The water flows again thanks to you."})
      else
        if current_cell.piece == 3 or current_cell.piece == 5 then
          if     flow_incomming_from == 1 and flow_from_to(current_cell_id, current_cell_id + p_width) then
            add(flowing_path, current_cell_id + p_width)
          elseif flow_incomming_from == 2 and flow_from_to(current_cell_id, current_cell_id - 1) then
            add(flowing_path, current_cell_id - 1)
          elseif flow_incomming_from == 3 and flow_from_to(current_cell_id, current_cell_id - p_width) then
            add(flowing_path, current_cell_id - p_width)
          elseif flow_incomming_from == 4 and flow_from_to(current_cell_id, current_cell_id + 1) then
            add(flowing_path, current_cell_id + 1)
          end
        elseif current_cell.piece == 4 or current_cell.piece == 6 then
          if flow_incomming_from == 1 then
            if current_cell.angle == .25 then 
              if flow_from_to(current_cell_id, current_cell_id - 1) then
                add(flowing_path, current_cell_id - 1) 
                flow_incomming_from = 2 
              end
            elseif current_cell.angle == .5 then
              if flow_from_to(current_cell_id, current_cell_id + 1) then
                add(flowing_path, current_cell_id + 1)
                flow_incomming_from = 4 
              end
            end
          elseif flow_incomming_from == 2 then
            if current_cell.angle == .5 then 
              if flow_from_to(current_cell_id, current_cell_id - p_width) then
                add(flowing_path, current_cell_id - p_width)
                flow_incomming_from = 3
              end
            elseif current_cell.angle == .75 then
              if flow_from_to(current_cell_id, current_cell_id + p_width) then
                add(flowing_path, current_cell_id + p_width)   
                flow_incomming_from = 1 
              end
            end
          elseif flow_incomming_from == 3 then
            if current_cell.angle == 0 then
              if flow_from_to(current_cell_id, current_cell_id - 1) then
                add(flowing_path, current_cell_id - 1)
                flow_incomming_from = 2
              end
            elseif current_cell.angle == .75 then 
              if flow_from_to(current_cell_id, current_cell_id + 1) then
                add(flowing_path, current_cell_id + 1)
                flow_incomming_from = 4
              end
            end
          elseif flow_incomming_from == 4 then
            if current_cell.angle == 0 then 
              if flow_from_to(current_cell_id, current_cell_id + p_width) then
                add(flowing_path, current_cell_id + p_width)       
                flow_incomming_from = 1   
              end
            elseif current_cell.angle == .25 then
              if flow_from_to(current_cell_id, current_cell_id - p_width) then
                add(flowing_path, current_cell_id - p_width)                       
                flow_incomming_from = 3             
              end                  
            end
          end
        end        
        if current_cell_id == flowing_path[#flowing_path] then counter_on = true end      
      end       
    end      
  end
  
  
  if btnp("cur_lb") then  
    local xp = btnv"cur_x"
    local yp = btnv"cur_y"
    in_flow = point_in_rect(xp, yp, 40, GH - 40, 120, GH - 8)
  elseif btnr("cur_lb") then
    if in_flow then
      screenshake(3)
      flowing_path = {p_start}
      counter_on = false
      in_flow = false
    end
  end
  
  if btnp("A") then   
    screenshake(3)
    flowing_path = {p_start}
    counter_on = false
    in_flow = false
  end  
  
end

function draw_background()
  cls(_palette[8])
  GW = screen_w()
  GH = screen_h()
  
  local r_size = 8
  local padding = 2
  local s = r_size + padding
  
  for j = -1, ceil(GH/s) do
    for i = -1, ceil(GW/s) do
      rectfill(i * s + cos(t() / 5) * 3, j * s + sin(t() / 5) * 3, i * s + r_size + cos(t() / 5) * 3, j * s + sin(t() / 5) * 3 + r_size , _palette[9])
    end
  end
end

local color_1 = _palette[2]
local color_2 = _palette[3]
local color_3 = _palette[4]
local color_4 = _palette[8]

function _draw()

  draw_background()
  
  -- Bubble
  
  local s_rect = 14
  local space = 2
  local w = s_rect + space
  
  local main_x = 32 - 8
  local main_y = (GH - p_height * w ) / 2 - 16 
  local step_y = sin(t() / 2) * 2
  
  local bubble_x = main_x + p_width * w + 28
  draw_bubble(main_x, main_y, p_width * w, p_height * w, 16)  
  
  -- Grid
  for j = 1, p_height do
    for i = 1, p_width do 
      local c = g[i + (j-1) * p_width]     
      local x = main_x + (i-1) * w
      local y = main_y + step_y + (j-1) * w 
      
      if c.piece == 1 or c.piece == 2 then
        outlined_glyph(g_spr.pieces[11],x + 8, y + 8, 16, 16, c.angle, _palette[0], _palette[0], 0)
      elseif c.piece == 7 or c.piece == 10 then
        outlined_glyph(g_spr.pieces[c.piece],main_x + (i-1) * w + 8, round(main_y + step_y + (j-1) * w + 8), 12, 12, c.angle, _palette[0], _palette[0], 0)
      else
        outlined_glyph(g_spr.pieces[c.piece],main_x + (i-1) * w + 8, main_y + step_y + (j-1) * w + 8, 16, 16, c.angle, _palette[0], _palette[0], 0)
      end
      

    end
  end
  
  for j = 1, p_height do
    for i = 1, p_width do 
      local c = g[i + (j-1) * p_width]    
      local x = main_x + (i-1) * w
      local y = main_y + step_y + (j-1) * w
      if counter_on then
        if btnp("cur_lb") and c.piece < 7 and point_in_rect(btnv"cur_x", btnv"cur_y", x ,y, x + 16, y + 16) then
          screenshake(3)
          c.angle = (c.angle + .25)%1
        end  
        if btnp("cur_rb") and 
          point_in_rect(btnv"cur_x", btnv"cur_y", x, y, x + 16, y + 16) then
          screenshake(3)
            if c.piece == 5 then c.piece = 6 elseif c.piece == 6 then c.piece = 5 end
        end      
      end
      
      if c.piece == 1 or c.piece == 2 then
        glyph(g_spr.pieces[11],x + 8, y + 8, 16, 16, c.angle, color_1, color_2)
        outlined_glyph(g_spr.pieces[c.piece], main_x + (i-1) * w + 8, round(main_y + step_y + (j-1) * w + 8), 10, 10, c.angle, color_2, color_2, color_1)
      elseif c.piece == 8 or c.piece == 9 then
        glyph(g_spr.pieces[c.piece],main_x + (i-1) * w + 8, main_y + step_y + (j-1) * w + 8, 16, 16, c.angle, color_3, color_2)
      elseif c.piece == 7 or c.piece == 10 then
        glyph(g_spr.pieces[c.piece],main_x + (i-1) * w + 8, round(main_y + step_y + (j-1) * w + 8), 12, 12, c.angle, color_3, color_2)
      else
        glyph(g_spr.pieces[c.piece],main_x + (i-1) * w + 8, main_y + step_y + (j-1) * w + 8, 16, 16, c.angle, color_1, color_2)
      end

    end
  end
  
  if flowing_path and #flowing_path > 0 and not counter_on then
    for i, id in pairs(flowing_path) do    
      local current_cell_id = id
      
      local x = main_x + ((current_cell_id-1) % p_width) * w + 8
      local y = main_y + step_y + flr((current_cell_id-1)/p_width) * w + 8
      
      -- rectfill(x - 2, y - 2, x + 2, y + 2, _palette[8])
      outlined_glyph(g_spr.water, x, y, 8, 8, 0, _palette[8], _palette[0], 0)   
    end  
  end  
    
    
  local main_x = 32
  local main_y = (GH - p_height * w ) / 2 + 50
  
  -- Bubble
  local bubble_x = main_x + p_width * w + 35 - 10
  draw_bubble(bubble_x, 25+ 43, 48, 48, 16)    
  -- Timer
  local str = "Score"
  local timer_x = (GW + (main_x + p_width  * w )) / 2 - str_px_width(str)/2 - 2
  local timer_y = main_y - 16
  step_y = sin(t() / 2 + .75/2) * 2
  pprint(str, timer_x, timer_y + step_y)
  
  local str = max(ceil((time_left) * 10)/10, 0)
  local timer_x = (GW + (main_x + p_width  * w )) / 2 - str_px_width(str)/2 - 2
  pprint(str, timer_x, timer_y + step_y + 16 + 8)
    
  -- Validation 
  
  local str = "Flow!"
  local main_x = 32 + 16 + 7
  local main_y = GH - 64 + 16 + 16 + (in_flow and 2 or 0) + 3
  local step_y = sin(t() / 2 + .25/2) * 2
  
  local bubble_x = main_x + p_width * w + 28
  draw_bubble(main_x, main_y, 64, 16, 16, in_flow and _palette[7] or _palette[6] , _palette[5])  
  pprint(str, main_x + 12, main_y + step_y - 4) 
    
end

-- xxxxx -------------

-- misc  -------------

function draw_bubble(x, y, width, height, rect_size, c1, c2)

  local x = x or 0
  local y = y or 0
  local rect_size = rect_size or 8
  local width = width or 16
  local height = height or 16
  
  local c1 = c1 or _palette[3]
  local c2 = c2 or _palette[5]
  
  local r = rect_size
  local xa = x + r/2
  local ya = y + r/2
  local xb = x + width - r/2
  local yb = y + height - r/2
  
  circfill(xa, ya, r, c2)
  circfill(xb, ya, r, c2)
  circfill(xa, yb, r, c2)
  circfill(xb, yb, r, c2)
  
  rectfill(xa, ya - r, xb, ya - r + 3, c2)
  rectfill(xa, yb + r - 3, xb, yb + r, c2)
  rectfill(xa - r, ya, xa - r + 3, yb, c2)
  rectfill(xb + r - 3, ya, xb + r, yb, c2)
  
  circfill(xa, ya, r-2, c1)
  circfill(xb, ya, r-2, c1)
  circfill(xa, yb, r-2, c1)
  circfill(xb, yb, r-2, c1)
  
  rectfill(xa - r + 2, ya, xb + r - 2, yb, c1)
  rectfill(xa, ya - r + 2, xb, ya, c1)
  rectfill(xa, yb, xb, yb + r - 2, c1)
  
end

function working_path_to_full_grid( path)
  if not path then return end
  
  local w = p_width
  local h = p_height
  local g = {} -- grid
  for i = 1, w * h do 
    local piece = 0 -- 1 for start, 2 for end, 3 for tube, 4 for corner and 5 for y shape
    local angle = 0 -- visual
    local v = value_in(i, path)
    if v then
    -- start
      if i == p_start then piece = 1 
    -- finish
      elseif i == p_end then piece = 2  
      else   
        local p_c = path[v-1] -- previous cell
        local n_c = path[v+1] -- next cell  
        local v   = path[v]
        if p_c == n_c - 2 or p_c == n_c + 2 or p_c == n_c - p_width * 2 or  p_c == n_c + p_width * 2 then 
        -- next is aligned
          piece = 3          
          if p_c == v - p_width or p_c == v + p_width then angle = -.25 end
        else
        -- next isnt
          piece = 4          
          
          if p_c == v - 1 or  n_c == v - 1 then   
            if n_c == v - p_width or p_c == v - p_width then
              angle = angle + .25      
            end  
          elseif p_c == v + 1 or  n_c == v + 1 then   
            angle = .5
            if n_c == v + p_width or p_c == v + p_width then
              angle = angle + .25      
            end          
          end      
          angle = irnd(4) * .25  
        end
        -- if irnd(100) < 33 then piece = 5 end 
      end
    else
      piece = 3 + irnd(7)
    end
    add(g, {piece = piece, angle = (angle + 1) % 1}) 
  end
  return g
end

function give_points( points)
  if not points or not _score then return end
  _score = _score + points
end

function point_in_rect(xp, yp, x1, y1, x2, y2)
  return xp > x1 and xp < x2 and yp > y1 and yp < y2
end

function copy(obj)
  if type(obj) ~= 'table' then return obj end
  local res = setmetatable({}, getmetatable(obj))
  for k, v in pairs(obj) do res[copy(k)] = copy(v) end
  return res
end

-- search algo

grid = {}
working_path = {}  
p_start = 0
p_end = 0
p_width = 8
p_height = 8

function generate_path()
  
  grid = {}  
  local width, height = p_width, p_height
  local k = irnd(2)
  p_start = (k == 0 and 1 or p_width)
  p_end   = (k == 1 and (width *height - p_width + 1) or width*height)
  
  for i = 0, width*height - 1 do
    local neighbors = {}
    
    if i >= width then               add(neighbors, "up")   end    
    if i%width < width - 1 then      add(neighbors, "right")end    
    if i <  width * (height-1) then  add(neighbors, "down") end    
    if i%width > 0 then              add(neighbors, "left") end
    
    add(grid, {n = neighbors} ) 
  end  
  go_to_call = 0
  go_to(p_start)

end

function go_to(cell_ind, path)
  if not cell_ind or not grid[cell_ind] then return end
  if value_in(cell_ind, path) then return end
  if ABORT then return end
  go_to_call = go_to_call + 1
  local path = path or {}
  local n = grid[cell_ind].n
  
  add(path, cell_ind)
  
  if cell_ind == p_end then 
    add_path(path)
  else
    local c_n = copy(n)
    
    while #c_n > 0 do 
      local ind = irnd(#c_n) + 1
      local way = c_n[ind]
      if way == "up" then
        go_to(cell_ind - p_width, path)
      end
      
      if way == "right" then
        go_to(cell_ind + 1 , path)
      end
      
      if way == "down" then
        go_to(cell_ind + p_width, path)
      end
      
      if way == "left" then
        go_to(cell_ind - 1, path)
      end
      
      del_at(c_n, ind)
    end
  end  
  
  del_at(path, #path)

end

function add_path(path)
  add(working_path, copy(path))
  if #working_path > 10 then
    ABORT = true
  end
end

function value_in(value, tab)  
  if not tab then return end
  for i, v in pairs(tab) do
    if value == v then return i end
  end
end

function value_in_tab_in(tab1, tab2)  
  if not tab then return end
  for i1, v1 in pairs(tab1) do
    for i2, v2 in pairs(tab2) do
      if v1 == v2 then return {i1, i2} end
    end
  end
end
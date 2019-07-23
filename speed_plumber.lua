require("framework/framework")

_title = "Speed Plumber"
-- _title = "Game Template"
-- _title = "Game Template 2"

_description = "Water flows, so does time !"

_palette = { ["0"] = 0, 8, 14, 13, 20, 4, 10, 15}

_controls = {

  [ "cur_x"  ] = "Hover on piece you want to move!",
  [ "cur_y"  ] = "Hover on piece you want to move!",
  
  [ "cur_lb" ] = "Rotate!",
  [ "cur_rb" ] = "Special Movement!"
}

_score = 0

local GW, GH = 0, 0
local time_since_launch = 0
local t = function() return time_since_launch or 0 end


local time_per_piece = .5
local flow_anim_timer

local flow_incomming_from -- 1 for up, 2 for right, 3 for down, 4 for left
local flowing_path

function _init(difficulty)
  GW = screen_w()
  GH = screen_h()
  
  g_spr = {
    arrow  = 0x43,    
    flag   = 0x44,    
    pieces = {0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49},    
    bubble = {0x4A, 0x4B, 0x4C, 0x4D, 0x4E   },    
  }
    
  local difficulty = difficulty or (25 + irnd(75))  
  
  generate_path()
  way = working_path[1]
    g = working_path_to_full_grid(way)
  
  level_completed = 0
  in_flow = false
  counter_on = true
  time_left = 45
  time_per_piece = .2
  flow_anim_timer = time_per_piece
  
end

local index = 1

function _update()

  time_since_launch = time_since_launch + dt()
  
  if counter_on then
    time_left = time_left - dt()
  else
    flow_anim_timer = flow_anim_timer + dt()
    -- punch_flow = punch_flow * (1 + dt())
    
    if flow_anim_timer < 0 then
      local current_cell    = g[#flowing_path]
      local current_cell_id = flowing_path[#flowing_path]
      flow_anim_timer = time_per_piece
      if current_cell_id == p_start then
        if flow_from_to(p_start, p_start + 1) then
          log("from start to right")
          flow_incomming_from = 4
          add(flowing_path, p_start + 1)
        elseif flow_from_to(p_start, p_start + p_width) then
          log("from start to down")
          flow_incomming_from = 1
          add(flowing_path, p_start + p_width)
        end  
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
            if angle == .25 then 
              if flow_from_to(current_cell_id, current_cell_id - 1) then
                add(flowing_path, current_cell_id - 1)
              end
            elseif angle == .5 then
              if flow_from_to(current_cell_id, current_cell_id + 1) then
                add(flowing_path, current_cell_id + 1)
              end
            end
          elseif flow_incomming_from == 2 then
            if angle == .5 then 
              if flow_from_to(current_cell_id, current_cell_id - p_width) then
                add(flowing_path, current_cell_id - p_width)
              end
            elseif angle == .75 then
              if flow_from_to(current_cell_id, current_cell_id + p_width) then
                add(flowing_path, current_cell_id + p_width)
              end
            end
          elseif flow_incomming_from == 3 then
            if angle == 0 then
              if flow_from_to(current_cell_id, current_cell_id + 1) then
                add(flowing_path, current_cell_id + 1)
              end
            elseif angle == .75 then 
              if flow_from_to(current_cell_id, current_cell_id - 1) then
                add(flowing_path, current_cell_id - 1)
              end
            end
          elseif flow_incomming_from == 4 then
            if angle == 0 then 
              if flow_from_to(current_cell_id, current_cell_id + p_width) then
                add(flowing_path, current_cell_id + p_width)
              end
            elseif angle == .25 then
              if flow_from_to(current_cell_id, current_cell_id - p_width) then
                add(flowing_path, current_cell_id - p_width)
              end
            end
          end
          
        end  
      end       
    end
  end
  
  if btnp("A") or btnp("cur_rb") then 
  
  end  
  
  if btnp("cur_lb") then  
    local xp = btnv"cur_x"
    local yp = btnv"cur_y"
    in_flow = point_in_rect(xp, yp, 40, GH - 40, 120, GH - 8)
  elseif btnr("cur_lb") then
    if in_flow then
      flowing_path = {p_start}
      counter_on = false
      in_flow = false
    end
  end
end

function cell_to_ind(cell)
  local piece = cell.piece
  local angle = cell.angle
  

end




function _draw()
  cls(_palette[1])
  
  -- Bubble
  
  local s_rect = 14
  local space = 2
  local w = s_rect + space
  
  local main_x = 32 - 8
  local main_y = (GH - p_height * w ) / 2 - 16 
  local step_y = sin(t() / 2) * 2
  
  local bubble_x = main_x + p_width * w + 28
  draw_bubble(main_x, main_y, p_width * w, p_height * w, 16)  
  
  -- local piece_animated = count_piece
  
  for j = 1, p_height do
    for i = 1, p_width do 
      local c = g[i + (j-1) * p_width]
      -- local xx, yy
      
      -- if count_piece then
        -- v = value_in(i + (j-1) * p_width, path)
        -- if v == way[count_piece] then
         -- xx = irnd(3 * punch_flow)
         -- yy = irnd(3 * punch_flow)
        -- end
      -- end
      
      outlined_glyph(g_spr.pieces[c.piece],main_x + (i-1) * w + 8, main_y + step_y + (j-1) * w + 8, 16, 16, c.angle, _palette[0], _palette[0], 0)    
    end
  end
  
  for j = 1, p_height do
    for i = 1, p_width do 
      local c = g[i + (j-1) * p_width]    
      if btnp("cur_lb") and c.piece < 7 and 
        point_in_rect(btnv"cur_x", btnv"cur_y", main_x + (i-1) * w ,main_y + step_y + (j-1) * w, main_x + (i-1) * w + 16,main_y + step_y + (j-1) * w  + 16) then
          c.angle = c.angle + .25
      end  
      if btnp("cur_rb") and 
        point_in_rect(btnv"cur_x", btnv"cur_y", main_x + (i-1) * w ,main_y + step_y + (j-1) * w, main_x + (i-1) * w + 16,main_y + step_y + (j-1) * w  + 16) then
          if c.piece == 5 then c.piece = 6 elseif c.piece == 6 then c.piece = 5 end
      end      
      
      glyph(g_spr.pieces[c.piece], main_x + (i-1) * w + 8, main_y + step_y + (j-1) * w + 8, 16, 16, c.angle, _palette[2], _palette[3], 0)    
    end
  end
  
  local main_x = 32
  local main_y = (GH - p_height * w ) / 2
  
  -- Bubble
  local bubble_x = main_x + p_width * w + 35 - 2
  draw_bubble(bubble_x, 25, 48, 48, 16)    
  -- Timer
  local str = "Timer"
  local timer_x = (GW + (main_x + p_width  * w )) / 2 - str_px_width(str)/2 - 2
  local timer_y = main_y - 16
  step_y = sin(t() / 2 + .75/2) * 2
  pprint(str, timer_x, timer_y + step_y)
  
  local str = max(ceil((time_left) * 10)/10, 0)
  local timer_x = (GW + (main_x + p_width  * w )) / 2 - str_px_width(str)/2 - 2
  pprint(str, timer_x, timer_y + step_y + 16 + 8)
  
  -- Bubble
  local bubble_x = main_x + p_width * w + 28 - 2
  draw_bubble(bubble_x, 100 - 4, 48 + 16 , 48, 16)    
  -- Completed lvl counter
  local str = "Completed"
  local lvl_x = (GW + (main_x + p_width  * w )) / 2 - str_px_width(str)/2
  local lvl_y = main_y + 64 - 4
  step_y = sin(t() / 2 + .50/2) * 2    
  pprint(str, lvl_x, lvl_y + step_y) 
  
  local str = level_completed
  local lvl_x = (GW + (main_x + p_width  * w )) / 2 - str_px_width(str)/2
  pprint(str, lvl_x, lvl_y + step_y + 16 + 8) 
    

  -- Validation 
  
  local str = "Flow!"
  local main_x = 32 + 16 
  local main_y = GH - 64 + 16 + 16 + (in_flow and 2 or 0)
  local step_y = sin(t() / 2 + .25/2) * 2
  
  local bubble_x = main_x + p_width * w + 28
  draw_bubble(main_x, main_y, 64, 16, 16, in_flow and _palette[7] or _palette[6] , _palette[2])  
  pprint(str, main_x + 12, main_y + step_y - 4) 

    
end

-- xxxxx -------------

-- misc  -------------

function draw_bubble(x, y, width, height, rect_size, c1, c2)
  
  -- draw first, draw filling_rect until left <= h then draw last
  local xx = x or 0
  local yy = y or 0
  local r_size = rect_size or 8
  local total_w = width or 16
  local total_h = height or 16
  
  local c1 = c1 or _palette[3]
  local c2 = c2 or _palette[2]
  
  for i = 0, ceil(total_w / r_size) do
    for j = 0, ceil(total_h / r_size) do
    
      local x = xx + i * r_size
      local y = yy + j * r_size
      
      if i == 0 then
        if j == 0 then
          -- bubble1        
          glyph(g_spr.bubble[1], x, y, r_size, r_size, 0, c1, c2, 0) 
        elseif j == ceil(total_h / r_size) then
          -- bubble4
          glyph(g_spr.bubble[4], x, y, r_size, r_size, 0, c1, c2, 0)
        else
          -- vertical filling_rect (left border)
          glyph(g_spr.bubble[5], x, y, r_size, r_size, -.25, c1, c2, 0)
        end
      elseif i == ceil(total_w / r_size) then
        if j == 0 then
          -- bubble1
          glyph(g_spr.bubble[2], x, y, r_size, r_size, 0, c1, c2, 0)
        
        elseif j == ceil(total_h / r_size) then
          -- bubble4
          glyph(g_spr.bubble[3], x, y, r_size, r_size, 0, c1, c2, 0)
        else
          -- vertical filling_rect (right border)
          glyph(g_spr.bubble[5], x, y, r_size, r_size, .25, c1, c2, 0)
        end
      else
        if j == 0 then
          -- horizontal filling_rect (top border)
            glyph(g_spr.bubble[5], x, y, r_size, r_size, 0, c1, c2, 0)
        elseif j == ceil(total_h / r_size) then
          -- horizontal filling_rect (bottom border)
            glyph(g_spr.bubble[5], x, y, r_size, r_size, .5, c1, c2, 0)
        else
          rectfill(x - r_size/2, y - r_size/2, x + r_size/2, y + r_size/2, c1)
        end
      end
    end
  end
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
    add(g, {piece = piece, angle = angle}) 
    -- log("x = " .. (i - 1)%p_width .. ", y = " .. flr((i-1) / p_width) .. ", p = " .. piece .. ", a = " .. angle)
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
p_width = 7
p_height = 7

function generate_path()
  
  grid = {}  
  local width, height = p_width, p_height
  
  p_start = 1
  p_end = width*height
  
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



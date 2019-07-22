require("framework/framework")

_title = "Speed Plumber"
-- _title = "Game Template"
-- _title = "Game Template 2"

_description = "Water flows, so does time !"

_palette = { ["0"] = 0, 17, 14, 13, 20, 4}

_controls = {

  [ "cur_x"  ] = "Aim!",
  [ "cur_y"  ] = "Aim!",
  
  [ "cur_lb" ] = "Rotate!",
  [ "cur_rb" ] = "Special Move!"
}

_score = 0

local GW, GH = 0, 0
local time_since_launch = 0
local t = function() return time_since_launch or 0 end

function _init(difficulty)
  GW = screen_w()
  GH = screen_h()
  
  g_spr = {
    arrow  = 0x43,    
    flag   = 0x44,    
  }
  
  printp_color (_palette[6], _palette[4], _palette[3])
  
  local difficulty = difficulty or (25 + irnd(75))  
  log("Difficulty set to :" .. difficulty )
  
  generate_path()
  -- for i, ind in ipairs(working_path) do
    -- log(i)
  -- end
  way = working_path[1]
  
  local str = ""
  for i = 1, #way do      
    str = str .. " : " .. way[i] 
  end
  log(str)
  
  
end

local _timer = 0

local index = 1


function _update()

  time_since_launch = time_since_launch + dt()
  _timer = _timer + dt()
  
  if _timer > 1.5 then
    _timer = 0
    index = index + 1
    way = working_path[index]
  end
  
  if btnp("A") or btnp("cur_rb") then  
  end  
  if btnp("cur_lb") then  
  end
  
  -- way = working_path[flr(t()/20 + 1)]
  
end

function _draw()
  cls(_palette[1])
  
  local s_rect = 14
  local space = 2
  local w = s_rect + space
  
  for j = 1, p_height do
    for i = 1, p_width do 
      local v = value_in(i + (j-1) * p_width, way )
      local col = ((i + (j-1) * p_width == p_start) or (i + (j-1) * p_width == p_end)) and _palette[4] 
                  or ( v and _palette[5] or _palette[3] )
                  
                  
      rectfill(i * w, j * w, i * w + s_rect , j * w + s_rect , col)   

      if v then
        
        p = way[v+1]
        if p then
          local angle  = 0      
          if      p == way[v] - p_width then -- up
            angle = 0
          elseif  p == way[v] + 1 then -- right
            angle = .25        
          elseif  p == way[v] + p_width then -- down
            angle = .5
          else -- left
            -- log(p .. " == " .. v .. " + " .. p - v )
            angle = .75
          end
          outlined_glyph(g_spr.arrow, i * w + 8, j * w + 8, 16, 16, angle, _palette[2], _palette[3], 0)            
        else
         outlined_glyph(g_spr.flag, i * w + 8, j * w + 8, 16, 16, 0, _palette[2], _palette[3], 0)
        end
      end
      
    end
  end
  
  for j = 1, p_height do
    for i = 1, p_width do      
      -- pprint( (value_in(i + (j-1) * p_width, way) or "") , i * w, j * w + sin(t() ) * 2 - 2 )    
    end
  end
  
end

-- xxxxx -------------

-- misc  -------------

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
  p_end = ceil(width*height / 2)
  -- p_end = width*height
  
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



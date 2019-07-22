require("framework/framework.lua")

_title = "Tangle"
_description = "Untangle the ropes before the timer runs out!"

_player_glyph = 0x50

_controls = {
  right = "Untangle pair",
  down  = "Untangle pair",
  left  = "Untangle pair",
  up    = "Untangle pair"
}


local _difficulty

local bg_data
local tangles
local ropes
local rope_swing

local length = 16
local progress = 0.0001
local progv = 0
local timer = 90
local finished

local untangled = 0
local new_tangles = 0

function _init(difficulty)
  _difficulty = difficulty
  
  length = 16 + flr(_difficulty/100 * 176)

  init_background()
  init_tangles()
  
  timer = 90
end

function _update()
  if finished then
    the_end()
    return
  end
  

  local btns = { "left", "down", "up", "right" }
  for i = 1,4 do
    if btnp(btns[i]) then
      twist(i)
    end
  end
  
  
  local n
  for y = length, 1, -1 do
    local line = tangles[y]
    
    if line[1] or line[2] or line[3] or line[4] then
      n = y
      break
    end
  end
  
  if not n then -- untangled everything!
    finished = true
  end
  
  n = length-(n or 1) + 0.0001

  progv = progv + (n-progress) * 10 * dt()
  progress = progress + progv * dt()
  
  progv = progv * 0.9
  
  
  local n
  for y = length+8, 1, -1 do
    local s_line = rope_swing[y]
    for i = 1,5 do
      if s_line[i] then s_line[i] = lerp(s_line[i], 0, 5*dt()) end
    end
  end
  
  
  timer = timer - dt()
  if timer <= 0 then
    the_end()
  end
end

function _draw()
  draw_background()
  draw_bands()
  draw_tangles()
  draw_progression()
  draw_buttons()
  draw_timer()
end



function twist(i)
  local n
  for y = length, 1, -1 do
    local line = tangles[y]
    
    if line[i] then
      n = y
      untangled = untangled + 1
      break
    elseif line[i-1] or line[i+1] then
      n = y+1
      new_tangles = new_tangles + 1
      break
    end
  end
  
  if n >= length then return end
  
  if not n then
    n = 1
  end
  
  tangles[n][i] = not tangles[n][i]
  
  for y = n, length+8 do
    local t_line = tangles[y]
    local pr_line = ropes[y-1]
    local r_line = ropes[y]
    for x = i, i+1 do
      if t_line[x] then
        r_line[x] = pr_line[x+1]
        r_line[x+1] = pr_line[x]
      elseif not t_line[x-1] then
        r_line[x] = pr_line[x]
      end
    end
  end
  
  local f,j = 3, 1
  for y = n, min(length+8, n+32) do
    local line = rope_swing[y]
    
    line[i] = -j * f
    line[i+1] = j * f

    j = j + 1
  end
end

function the_end()
  local n
  for y = length, 1, -1 do
    local line = tangles[y]
    
    if line[1] or line[2] or line[3] or line[4] then
      n = y
      break
    end
  end
  
  local score
  if n then
    score = flr((1 - n/length) * 100)
  else
    score = 100
  end
  
  local stats = {}
  
  add(stats, "You untangled "..untangled.." knots!")
  add(stats, "You made "..new_tangles.." knots yourself!")
  
  if not n then
    add(stats, "You went all the way in only "..flr(90-timer).." secs!")
  else
    add(stats, "You went "..score.."% of the way!")
  end
  
  freeze(0.5)
  gameover(score, stats)
end



local colors = {
  {12, 4}, {13, 6}, {14, 13}, {15, 10}, {17, 18}
}
function draw_tangles()
  local scale = 3

  local ax = screen_w()/2 - 28 * scale
  
  local ynn = length - 4 - progress + 1.5
  
  local ay = -flr(((ynn % 1) * 16 + 8) * scale)
  ynn = flr(ynn)
  
  local y = ay
  for yn = ynn, ynn+5 do
    local line = tangles[yn]
    local r_line = ropes[yn]
    local s_line = rope_swing[yn]
    local x = ax
    
    if not line then
      goto next_line
    end
    
    clip(0, y-8*scale, screen_w(), scale*16)
    for i = 1,5 do
      if line[i] then
        glyph(0x52, x-scale, y, scale*16, scale*16, 0, 0, 0)
        glyph(0x52, x+scale, y, scale*16, scale*16, 0, 0, 0)
--        glyph(0x52, x, y-scale, scale*16, scale*16, 0, 0, 0)
        glyph(0x52, x, y+scale, scale*16, scale*16, 0, 0, 0)
        
        glyph(0x52, x+(15*scale)-scale, y, -scale*16, -scale*16, 0, 0, 0)
        glyph(0x52, x+(15*scale)+scale, y, -scale*16, -scale*16, 0, 0, 0)
        glyph(0x52, x+(15*scale), y-scale, -scale*16, -scale*16, 0, 0, 0)
--        glyph(0x52, x+(16*scale), y+scale, -scale*16, -scale*16, 0, 0, 0)
        
        glyph(0x52, x, y, scale*16, scale*16, 0, unpack(colors[r_line[i+1]]))
        glyph(0x52, x+(15*scale), y, -scale*16, -scale*16, 0, unpack(colors[r_line[i+1]]))

        glyph(0x52, x-scale, y, scale*16, -scale*16, 0, 0, 0)
        glyph(0x52, x+scale, y, scale*16, -scale*16, 0, 0, 0)
        glyph(0x52, x, y-scale, scale*16, -scale*16, 0, 0, 0)
        glyph(0x52, x, y+scale, scale*16, -scale*16, 0, 0, 0)
        
        glyph(0x52, x+(15*scale)-scale, y, -scale*16, scale*16, 0, 0, 0)
        glyph(0x52, x+(15*scale)+scale, y, -scale*16, scale*16, 0, 0, 0)
        glyph(0x52, x+(15*scale), y-scale, -scale*16, scale*16, 0, 0, 0)
        glyph(0x52, x+(15*scale), y+scale, -scale*16, scale*16, 0, 0, 0)
        
        glyph(0x52, x, y, scale*16, -scale*16, 0, unpack(colors[r_line[i]]))
        glyph(0x52, x+(15*scale), y, -scale*16, scale*16, 0, unpack(colors[r_line[i]]))
      elseif not line[i-1] then
        local dx = s_line[i] or 0
        glyph(0x50, x-scale + dx, y, scale*16, scale*16, 0, 0, 0)
        glyph(0x50, x+scale + dx, y, scale*16, scale*16, 0, 0, 0)
      end
      
      x = x + scale*15
    end
    clip()
    
    ::next_line::
    
    y = y + 16*scale
  end
  

  local y = ay
  for yn = ynn, ynn+5 do
    local line = tangles[yn]
    local r_line = ropes[yn]
    local s_line = rope_swing[yn]
    local x = ax
    
    if not line then
      if yn == 0 then
        local y = y-scale
        for i = 1, 5 do
          glyph(0x09, x-scale, y, scale*16, scale*16, 0, 0, 0)
          glyph(0x09, x+scale, y, scale*16, scale*16, 0, 0, 0)
          glyph(0x09, x, y-scale, scale*16, scale*16, 0, 0, 0)
          glyph(0x09, x, y+scale, scale*16, scale*16, 0, 0, 0)
          x = x + scale * 15
        end
        
        x = ax
        for i = 1, 5 do
          glyph(0x09, x, y, scale*16, scale*16, 0, 29, 27)
          x = x + scale * 15
        end
      end
    
      goto next_line
    end
    
    for i = 1,5 do
      if not (line[i] or line[i-1]) then
        local dx = s_line[i] or 0
        glyph(0x50, x+dx, y, scale*16, scale*16, 0, unpack(colors[r_line[i]]))
      end

      x = x + scale*15
    end
    
    ::next_line::
    
    y = y + 16*scale
  end

end


function init_tangles()
  local len = length

  tangles = {}
  for y = 1, len + 8 do
    tangles[y] = {}
  end
  
  local n = flr(len*1.5)
  
  while n > 0 do
    for y = 1, len - 2 do
      if chance(50) then
        local line = tangles[y]
        local k = irnd(4)+1
        if not (line[k] or line[k-1] or line[k+1]) then
          line[k] = true
          n = n - 1
          
          if n <= 0 then break end
        end
      end
    end
  end
  
  ropes = { [0] = {1, 2, 3, 4, 5} }
  rope_swing = {}
  for y = 1, len+8 do
    local t_line = tangles[y]
    local pr_line = ropes[y-1]
    local r_line = {}
    for x = 1, 5 do
      if t_line[x] then
        r_line[x] = pr_line[x+1]
        r_line[x+1] = pr_line[x]
      elseif not t_line[x-1] then
        r_line[x] = pr_line[x]
      end
    end
    
    ropes[y] = r_line
    rope_swing[y] = {}
  end
end



function draw_lines()
  local r_scale = 3
  local ax = screen_w()/2 - 28 * r_scale
  
  local btns = {[0]="", "left", "down", "up", "right", ""}

  local l,s = 4,12
  for y = -((-t()*16)%(l+s)), screen_h(), l+s do
    local x = ax
  
    for i = 1,5 do
      if btn(btns[i]) or btn(btns[i-1]) then
        line(x, y, x, y+l, 3)
        pset(x, y, 19)
        pset(x, y+l, 19)
      else
        line(x, y, x, y+l, 29)
        pset(x, y, 27)
        pset(x, y+l, 27)
      end
    
      x = x + 15 * r_scale
    end
  end
end

function draw_bands()
  local r_scale = 3
  local x = screen_w()/2 - 28 * r_scale
  
  local btns = { "left", "down", "up", "right" }
  
  for i = 1,4 do
    if btn(btns[i]) then
      rectfill(x, 0, x+10*r_scale, screen_h(), 29)
    end
  
    x = x + 15 * r_scale
  end
end

function draw_buttons()
  draw_lines()

  local btns = { "left", "down", "up", "right" }
  local dirs = { 0, 0.75, 0.25, 0.5 }
  
  local y = screen_h() - 16
  
  local r_scale = 3
  local x = screen_w()/2 - 21.5 * r_scale
  
  for i = 1, 4 do
    local a = 0.05*cos(i*0.1 - 0.25*t())
  
    if btn(btns[i]) then
      outlined_glyph(0x0b, x, y+4, 20, 20, a, 19, 3, 0)
      glyph(0x13, x, y+4, 14, 14, a-0.125+dirs[i], 0, 3)
    else
      outlined_glyph(0x0b, x, y+4, 20, 20, a, 19, 3, 0)
      outlined_glyph(0x0b, x, y, 20, 20, a, 29, 27, 0)
      glyph(0x13, x, y, 14, 14, a-0.125+dirs[i], 19, 27)
    end
    
    x = x + 15 * r_scale
  end
  
end

function draw_progression()
  local x,y = 12, screen_h()/2
  
  local h = 128
  y = y - h/2
  
  rectfill(x-3, y, x+2, y+h-1, 0)
  rectfill(x-2, y-1, x+1, y+h, 0)
  
  rectfill(x-2, y, x+1, y+h-1, 29)
  pset(x-2, y, 27)
  pset(x+1, y, 27)
  pset(x-2, y+h-1, 27)
  pset(x+1, y+h-1, 27)
  
  local v = progress/(length-1)
  
  y = y + (1 - v) * h
  
  outlined_glyph(0x07, x, y, 8, 8, 0.1, 27, 19, 0)
  outlined_glyph(0x07, x, y-2, 8, 8, 0.1, 29, 27, 0)
end

function draw_timer()
  if timer < 5 and timer % 1 > 0.75 then
    return
  end

  local str = ""..flr(timer)
  local x = (screen_w() - (str_px_width(str) + 20))/2
  local y = 4
  
  outlined_glyph(0x72, x+8, y+8, 16, 16, 0.05*cos(0.5*t()), 0, 27, 29)
  
  x = x + 20
  printp(0x0300, 0x3130, 0x3230, 0x0300)
  printp_color(0, 27, 29)
  
  for i = 1,#str do
    local ch = str:sub(i,i)
    pprint(ch, x, y + ((i + flr(timer))%2 - 0.5) * 4)
    x = x + str_px_width(ch)
  end
end


local bg_cols
function draw_background()
  local ca, cb, cc = unpack(bg_cols)
  
  cls(cc)
  
  local nny = -progress * 2

  local y = -(nny % 1) * 16
  nny = flr(nny)
  
  for ny = nny, nny + 12 do
    local line = bg_data[ny % 32]
    
    for x = 0,15 do
      local v = line[x]
      
      if v >= 0x90 then
        glyph(v, x*16 + 8, y + 8, 16, 16, 0, ca, cb)
      elseif v > 0 then
        glyph(v, x*16 + 8, y + 8, 16, 16, 0, ca, ca)
      end
    end
    
    y = y + 16
  end
end

function init_background()
  local len = 32

  local grid = {}
  for y = 0, len-1 do
    local line = {}
    for x = 0, 16 do
      line[x] = irnd(2)
    end
    
    grid[y] = line
  end
  
  
  bg_data = {}
  
  for y = 0, len-1 do
    local line = {}
  
    local line_a = grid[y]
    local line_b = grid[(y+1)%len]
    
    for x = 0,15 do
      local v = line_a[x] + line_a[x+1]*2 + line_b[x]*4 + line_b[x+1]*8
      
      if v == 0 and chance(75) then
        v = 0
      elseif (v == 3 or v == 5 or v == 10 or v == 12) and chance(75) then
        v = 0x80 + v
      else
        v = 0x90 + v
      end
      
      line[x] = v
    end
    
    bg_data[y] = line
  end
  
  bg_cols = pick{
    { 29, 28, 27 }
  }
end



function chance(n) return rnd(100) < n end
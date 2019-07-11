require("framework")

_name = "Fishing Game"
_description = "Some test indeed !"

_palette = {0, 17, 14, 13, 20, 4}


_controls = {
  [ "up"     ] = "Move!",
  [ "down"   ] = "Move!",
  [ "left"   ] = "Move!",
  [ "right"  ] = "Move!",

  [ "A"      ] = "Jump!",
  [ "B"      ] = "Crouch!",

  [ "cur_x"  ] = "Aim!",
  [ "cur_y"  ] = "Aim!",
  [ "cur_lb" ] = "Shoot!",
  [ "cur_rb" ] = "Send movie to director!"
}

_objects = {}

local x,y = 128,96
local GW, GH = 0, 0

function _init(w, h)
  GW = w or 0
  GH = h or 0
  use_font("not_main")
  
end

function _update()
  x = x - btnv("left") + btnv("right")
  y = y - btnv("up") + btnv("down")
  
  if btnp("A") or btnp("cur_rb") then
    add(_objects, {spr = 0x03,  p = {x = btnv("cur_x"), y = btnv("cur_y")}})  
  end
    
  if btnp("B") or btnp("cur_lb") then
    _objects = {}  
  end
  
  if btnp("cur_lb") then
    local i = 0
    for id, game in pairs(get_game_list()) do
      local x = GW / 6 + i * GW/3
      local y = 50
      
      local x_mouse = btnv("cur_x")
      local y_mouse = btnv("cur_y")
      
      if point_in_rect(x_mouse, y_mouse, x, y, x + 15, y + 15) then launch_game(id) end  
      
      i = i + 1
      
    end
  end
  
end

function point_in_rect(xp, yp, x1, y1, x2, y2)
  return xp > x1 and xp < x2 and yp > y1 and yp < y2
end

function _draw()
  cls(1)
  
  print(_name, GW / 2 - sugar.gfx.str_px_width(_name)/2, 2, flr(t()* 3)) 
    
  -- list of games
  -- this should be in end screen of framework, testing purpose only
  
    local i = 0
    local j = (flr(t())) % (#_palette)
    log(j)
    local col = _palette[j]
    color(col)
    for id, game in pairs(get_game_list()) do
      local x = GW / 6 + i * GW/3
      local y = 50
      print(id, x, y)
      print(game.name, x - str_px_width(game.name)/2, y + 15)
      rectfill(x, y, x + 15, y + 15, col + 1)
      i = i + 1
    end
  
  --
    
  local a = atan2(btnv"cur_x" - x, btnv"cur_y" - y)
  outlined_glyph(0x20, x, y, 16, sgn(cos(a)) * (16 + 2*sin(t())), a, _palette[2], _palette[3], 0)
  
 -- circ(btnv("cur_x"), btnv("cur_y"), btn("cur_rb") and 6 or btn("cur_lb") and 12 or 3, 4)
  outlined_glyph(0x00, btnv("cur_x"), btnv("cur_y"), 8 + 8 * btnv("cur_lb"), 8 + 8 * btnv("cur_rb"), 0, _palette[4], _palette[5], 0)
  
end

function point_in_rect(xp, yp, x1, y1, x2, y2)
  return xp > x1 and xp < x2 and yp > y1 and yp < y2
end

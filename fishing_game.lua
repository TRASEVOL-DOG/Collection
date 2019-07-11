require("framework")


_name = "Testing!"
_description = "This is just a test, really."

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
  
  
end

function _draw()
  cls(1)
  
  print("Fishing Game", GW / 2 - sugar.gfx.str_px_width("Fishing Game")/2, 2, flr(t()* 3)) 
    
  -- list of games

  if _game_list then log("here") end
    
    
  local a = atan2(btnv"cur_x" - x, btnv"cur_y" - y)
  outlined_glyph(0x20, x, y, 16, sgn(cos(a)) * (16 + 2*sin(t())), a, 2, 3, 0)
  
 -- circ(btnv("cur_x"), btnv("cur_y"), btn("cur_rb") and 6 or btn("cur_lb") and 12 or 3, 4)
  outlined_glyph(0x00, btnv("cur_x"), btnv("cur_y"), 8 + 8 * btnv("cur_lb"), 8 + 8 * btnv("cur_rb"), 0, 4, 5, 0)
  
  
  
  
  
  
  
end

function point_in_rect(xp, yp, x1, y1, x2, y2)
  return xp > x1 and xp < x2 and yp > y1 and yp < y2
end

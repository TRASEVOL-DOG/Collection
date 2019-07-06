require("framework/framework.lua")
require("socket")
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
function _init()


end

function _update()
  x = x - btnv("left") + btnv("right")
  y = y - btnv("up") + btnv("down")
  
  if btnp("A") then
    add(_objects, {spr = 0x03,  p = {x = btnv("cur_x"), y = btnv("cur_y")}})  
  end
  
  if btnp("B") then
    local ind = irnd(#_game_registery) + 1
    local url = _game_registery[ind]
    
    log("portal to game number " .. ind)
    log("url =  " .. url)
    
    castle.game.load(
      url, {
        objects = _objects,
        _game_registery = _game_registery
      }
    )
  end
  
end

function _draw()
  cls(1)
  
  glyph(0x03, 32, 32, 16, 16, 2*t(), 2, 3)
  
  for _, obj in pairs(_objects) do
    glyph(obj.spr, obj.p.x, obj.p.y, 16, 16, 2*t(), 2, 3)  
  end
  
--  circfill(x, y, 7, 2)
  local a = atan2(btnv"cur_x" - x, btnv"cur_y" - y)
  outlined_glyph(0x20, x, y, 16, sgn(cos(a)) * (16 + 2*sin(t())), a, 2, 3, 0)
  
--  circ(btnv("cur_x"), btnv("cur_y"), btn("cur_rb") and 6 or btn("cur_lb") and 12 or 3, 4)
  outlined_glyph(0x00, btnv("cur_x"), btnv("cur_y"), 8 + 8 * btnv("cur_lb"), 8 + 8 * btnv("cur_rb"), 0, 4, 5, 0)
  
end

require("framework")

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
  
  -- glyph(0x03, 32, 32, 16, 16, 2*t(), 2, 3)
  
    
  -- games 
  -- for i, game in pairs(_game_registery) do
    -- rectfill(0,(i)*24, str_px_width(game.name), (i+1)*24, flr(t()* 3) + 1)
    -- print(game.name, 0, i*24, flr(t()* 3))  
    -- glyph(game.player_spr, str_px_width(game.name), i*24, 16, 16, 2*t(), 2, 3) 
    
    -- if btnp("cur_lb") and point_in_rect(btnv("cur_x"),btnv("cur_y"), 0,i*24, str_px_width(game.name), (i+1)*24) then
      -- go_to_game(i)
    -- end
  -- end
  
  -- name of this game
    print("Fishing Game", GW / 2 - sugar.gfx.str_px_width("Fishing Game")/2, 2, flr(t()* 3)) 
  -- objects
  -- for _, obj in pairs(_objects) do
    -- glyph(obj.spr, obj.p.x, obj.p.y, 16, 16, 2*t(), 2, 3)  
  -- end
  
 -- circfill(x, y, 7, 2)
  local a = atan2(btnv"cur_x" - x, btnv"cur_y" - y)
  outlined_glyph(0x20, x, y, 16, sgn(cos(a)) * (16 + 2*sin(t())), a, 2, 3, 0)
  
 -- circ(btnv("cur_x"), btnv("cur_y"), btn("cur_rb") and 6 or btn("cur_lb") and 12 or 3, 4)
  outlined_glyph(0x00, btnv("cur_x"), btnv("cur_y"), 8 + 8 * btnv("cur_lb"), 8 + 8 * btnv("cur_rb"), 0, 4, 5, 0)
  
  
  
  
end


function point_in_rect(xp, yp, x1, y1, x2, y2)
  return xp > x1 and xp < x2 and yp > y1 and yp < y2
end

function go_to_game(index_game)
  local url = _game_registery[index_game].url_main
  
  log("going to .. " .. _game_registery[index_game].name )    
  log("url =  " .. url)
  
  castle.game.load(
    url, {
      objects = _objects,
      _game_registery = _game_registery
    }
  )
end

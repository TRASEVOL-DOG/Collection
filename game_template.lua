require("framework/framework.lua")

_palette = {1, 3, 5, 7, 9, 11}

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


local x,y = 128,96
function _init()

end

function _update()
  x = x - btnv("left") + btnv("right")
  y = y - btnv("up") + btnv("down")
  
  if btn("A") then
    -- ??
  end
end

function _draw()
  cls(0)
  
  circfill(x, y, 7, 2)
  
  circ(btnv("cur_x"), btnv("cur_y"), btn("cur_rb") and 6 or btn("cur_lb") and 12 or 3, 4)
end
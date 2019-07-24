require("framework/framework")

_title = "This is the title."
_description = "This is the description."

_player_glyph = 0x01 -- set this to a glyph central to your game!

_controls = { -- try to just use a few!
  [ "right"  ] = "Do thing A!",
  [ "down"   ] = "Do thing A!",
  [ "left"   ] = "Do thing A!",
  [ "up"     ] = "Do thing A!",

  [ "A"      ] = "Do thing B!",
  [ "B"      ] = "Do thing C!",

  [ "cur_x"  ] = "Do thing D!",
  [ "cur_y"  ] = "Do thing D!",
  [ "cur_lb" ] = "Lose!",
  [ "cur_rb" ] = "Win!"
}

_cursor_info = {
  glyph = 0x10,
  color_a = 29,
  color_b = 27,
  outline = 0,
  point_x = 8,
  point_y = 8,
  angle = 0
}


function _init(difficulty)
  -- difficulty goes from 0.
  -- for scale, 100 should be extremely difficult.
end

function _update()
  if btnp("cur_lb") then
    gameover(25, {"Hello.", "You should've right-clicked. :/"})
  end

  if btnp("cur_rb") then
    screenshot() -- use this to make a preview for the game!
    gameover(100, {"hello!", "yess", "you did it!"})
  end

  _cursor_info.angle = 0.5 * t()
end


function _draw()
  cls(3)
  
  outlined_glyph(0x0d, screen_w()/2, screen_h()/2, 16, 16, 0.1*cos(t()), 12, 5, 0)
end

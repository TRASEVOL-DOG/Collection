-- yet another maze

require("framework/framework")

_title = "Candy Hunt"

_description = "Looks like somebody is dropping candies in that maze, quick get them !"

_player_glyph = 0x62

_controls = {
  [ "left" ] = "Move",
  [ "up" ] = "Move",
  [ "right" ] = "Move",
  [ "down" ] = "Move",
}

_score = 0

playground = {}


function _init(difficulty)

  difficulty = difficulty or irnd(100) + 1

  GW = screen_w()
  GH = screen_h()
  
  init_palette()
  init_playground()
  
  time_since_launch = 0
  
end

function _update()
  time_since_launch = time_since_launch + dt()
  update_playground()
end

function _draw()  
	draw_background()
	draw_playground()
end

function draw_background()
	
end

function init_playground(w, h)
	playground = {}
	local p = playground
	
	p.pixel_d = 8
	p.w  = w or 10
	p.h = h or 10
	p.x = 8
	p.y = 8
end

function update_playground()

end

function draw_playground()

end

function rf(x, y, w, h, col)
  rectfill( x, y, x + w, y + h, col)
end

function is_in(value, tab)  
  if not tab then return end
  for i, v in pairs(tab) do
    if value == v then return i end
  end
end

function init_palette()
	_palette = {
		{name = "bg", col = 17},
		{name = "black", col = 0},
		{name = "white", col = 29},

		{name = "warehouse1", col = 25},
		{name = "warehouse2", col = 24},

		{name = "player1", col = 24},
		{name = "player2", col = 27},

		{name = "camion1", col = 0},
		{name = "camion2", col = 29},

		{name = "box1", col = 0},
		{name = "box2", col = 29},

		{name = "rope", col = 0},
	}
end

function _p_i(index)
	if _palette[index] then return _palette[index].col end
end

function _p_n(name)
	for i, c in pairs(_palette) do
		if c.name == name then return c.col end
	end
end









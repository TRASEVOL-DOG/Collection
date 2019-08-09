local _debug = debug

require("framework/framework.lua")

---- Dodging environment restrictions

local getfenv, setfenv = getfenv, setfenv
local env_save = getfenv(1)

love.load()

local new_love = {
  load   = love.load,
  update = love.update,
  draw   = love.draw
}

love.load = nil
love.update = nil
love.draw = nil


-- local function definitions

local __load, __update, __draw, update_palette, draw_palette, update_glyphgrid, draw_glyphgrid, draw_cursor, on_resize
local load_game, save_game, delete_game, gen_game_id
local test_game, stop_testing, compile_foo, define_user_env
local find_foo, new_foo, update_def, delete_foo
local new_message
local ui_panel, remove_editor_panel, project_panel, info_editor, controls_edit, cursor_edit, function_editor, testing_ui
local point_in_rect

-- local variables

local game_info, functions, function_list, function_names, cur_function
local user_registry
local testing, compile_error, runtime_error
local message, message_t
local ui_panel




do
  local str = [[
#### `gameover(score, [stats])`
- Ends the game.
- `score` is the player's final score. It should be between 0 *(terrible, player didn't even try)* and 100. *(perfect)*
- `stats` *(optional)* is a table of up-to-5 strings, to be displayed on the gameover. You may use this to give the player more information on how they did in the game.

&#8202;

#### `glyph(n, x, y, width, height, angle, color_a, color_b, [anchor_x = 8, anchor_y = 8])`
- Draws the glyph `n` at the coordinates `x, y`, **stretched** to `width, height`, rotated by `angle` full turns, using `color_a` as main color and `color_b` as secondary color, centered on the point `anchor_x, anchor_y` on the glyph. *(in pixel coordinates, default is `8, 8`)*
- Every glyph's original size is 16x16.
- `color_b` is mostly used for anti-alias and details on the glyphs.
- `angle` is counted in *turns*, meaning `1` results in a full rotation, while `0.5` results in a half rotation. (180 degrees, Pi radians)

&#8202;

#### `outlined_glyph(n, x, y, width, height, angle, color_a, color_b, outline_color, [anchor_x = 8, anchor_y = 8])`
- Same as `glyph(...)` above, except a 1-pixel-thick outline is drawn around the glyph, using the color `outline_color`.

&#8202;

#### `screenshot()`
- Saves a screenshot of the game to `%appdata%\LOVE\Castle` if on Windows, and to `/Users/user/Library/Application Support/LOVE/Castle` if on Mac.
- The file's name will be `[game title].png`.

&#8202;

#### `screenshake(power)`
- Shakes the screen with `power` intensity.
- The intensity will be affected by the 'screenshake' user setting. (accessible in the game's pause panel once published)

&#8202;

#### `btn(input)`
- Returns the state (`true`/`false`) of the input `input`.
- `input` has to have been set in the "Game Info" panel.
- Correspondance between kayboard and controller is automated. Both will trigger the same defined inputs.
- You may use the following inputs: (as are available in the "Game Info" panel)
  - `right`
  - `down`
  - `left`
  - `up`
  - `A` *(Z or Shift on a keyboard)*
  - `B` *(X or Ctrl on a keyboard)*
  - `cur_x`
  - `cur_y`
  - `cur_lb`
  - `cur_rb`
  
&#8202;

#### `btnp(input)`
- "btnp" is short for "button press".
- Returns whether the input `input` is active but wasn't during the previous frame.

&#8202;

#### `btnr(input)`
- "btnr" is short for "button release".
- Returns whether the input `input` was active the previous frame but isn't anymore.

&#8202;

#### `btnv(input)`
- "btnv" is short for "button value".
- Returns a decimal number representing the state of the input.
- Particularly useful for `cur_x` and `cur_y`: `btnv("cur_x")` will give you the X mouse coordinate for example.
- Simple button inputs *(keyboard keys for example)* will return 1 when pressed and 0 when not.

&#8202;

## Sugarcoat functions

### Subcontent:
- Debug
  - [`log(str)`](#logstr-prefix)
  - [`w_log(str)`](#w_logstr)
  - [`r_log(str)`](#r_logstr)
  - [`assert(condition,str)`](#assert-conditionstr)
  - [`write_clipboard(str)`](#write_clipboardstr)
  - [`read_clipboard()`](#read_clipboard)

- GFX
  - [`screen_size()`](#screen_size)
  - [`screen_w()`](#screen_w)
  - [`screen_h()`](#screen_h)
  - [`camera(x, y)`](#camerax--0-y--0)
  - [`camera_move(dx, dy)`](#camera_movedx-dy)
  - [`get_camera()`](#get_camera)
  - [`clip(x, y, w, h)`](#clipx-y-w-h)
  - [`get_clip()`](#get_clip)
  - [`color(i)`](#colori)
  - [`pal(ca, cb, flip_level)`](#palca-cb-flip_level--false)
  - [`clear(c)`](#clearc--0)
  - [`cls(c)`](#clsc--0)
  - [`rectfill(xa, ya, xb, yb, c)`](#rectfillxa-ya-xb-yb-c)
  - [`rect(xa, ya, xb, yb, c)`](#rectxa-ya-xb-yb-c)
  - [`circfill(x, y, r, c)`](#circfillx-y-r-c)
  - [`circ(x, y, r, c)`](#circx-y-r-c)
  - [`trifill(xa, ya, xb, yb, xc, yc, c)`](#trifillxa-ya-xb-yb-xc-yc-c)
  - [`tri(xa, ya, xb, yb, xc, yc, c)`](#trixa-ya-xb-yb-xc-yc-c)
  - [`line(xa, ya, xb, yb, c)`](#linexa-ya-xb-yb-c)
  - [`pset(x, y, c)`](#psetx-y-c)
  - [`str_px_width(str)`](#str_px_widthstr)
  - [`print(str, x, y, c)`](#printstr-x-y-c)
  - [`printp(a, b, c, d)`](#printpa-b-c-d)
  - [`printp_color(c1, c2, c3)`](#printp_colorc1-c2-c3)
  - [`pprint(str, x, y, c1, c2, c3)`](#pprintstr-x-y-c1-c2-c3)

- Maths
  - [`cos(a)`](#cosa)
  - [`sin(a)`](#sina)
  - [`atan2(x, y)`](#atan2x-y)
  - [`lerp(a, b, i)`](#lerpa-b-i)
  - [`flr(a)`](#flra)
  - [`ceil(a)`](#ceila)
  - [`round(a)`](#rounda)
  - [`sgn(a)`](#sgna)
  - [`sqr(a)`](#sqra)
  - [`cub(a)`](#cuba)
  - [`pow(a, b)`](#powa-b)
  - [`sqrt(a)`](#sqrta)
  - [`abs(a)`](#absa)
  - [`min(a, b)`](#mina-b)
  - [`max(a, b)`](#maxa-b)
  - [`mid(a, b, c)`](#mida-b-c)
  - [`angle_diff(a1, a2)`](#angle_diffa1-a2)
  - [`dist(x1, y1, x2, y2)`](#distx1-y1-x2-y2)
  - [`sqrdist(x, y)`](#sqrdistx-y)
  - [`srand(seed)`](#srandseed)
  - [`raw_rnd()`](#raw_rnd)
  - [`rnd(n)`](#rndn)
  - [`irnd(n)`](#irndn)
  - [`pick(tab)`](#picktab)

- Time
  - [`t()`](#t)
  - [`time()`](#time)
  - [`dt()`](#dt)
  - [`delta_time()`](#delta_time)
  - [`freeze(sec)`](#freezesec)
  - [`sys_ltime()`](#sys_ltime)
  - [`sys_gtime()`](#sys_gtime)

- Utility
  - [`all(ar)`](#allar)
  - [`del(ar, val)`](#delar-val)
  - [`del_at(ar, n)`](#del_atar-n)
  - [`add(ar, v)`](#addar-v)
  - [`sort(ar)`](#sortar)
  - [`merge_tables(dst, src)`](#merge_tablesdst-src)
  - [`copy_table(tab, deep)`](#copy_tabletab-deep)
  
&#8202;

### Debug

#### `log(str, [prefix])`
- Puts a new line in the log with the information 'str'.
- If `prefix` is set, prints it in front of `str` instead of the default prefix. (` . `)
- `prefix` can only be up to 3 characters.

&#8202;

#### `w_log(str)`
- Puts a new **warning** line in the log with the information 'str'.

&#8202;

#### `r_log(str)`
- Puts a new **error** line in the log with the information 'str'.

&#8202;

#### `assert(condition, str)`
- Checks the condition and crashes if it isn't true. Logs and outputs the message 'str' on crash.

&#8202;

#### `write_clipboard(str)`
- Writes 'str' to the system clipboard.

&#8202;

#### `read_clipboard()`
- Reads the system clipboard.
- Returns the clipboard's content as a string.

&#8202;

### GFX

#### `screen_size()`
- Returns:
  - the width of the screen resolution. *(always 256 here)*
  - the height of the screen resolution. *(always 192 here)*

&#8202;

#### `screen_w()`
- Returns the width of the screen resolution. *(always 256 here)*

&#8202;

#### `screen_h()`
- Returns the height of the screen resolution. *(always 192 here)*

&#8202;

#### `camera([x = 0, y = 0])`
- Sets a coordinate offset of {-x, -y} for the following draw operations.
- Calling `camera()` resets this.

&#8202;

#### `camera_move(dx, dy)`
- Offsets the coordinate offset so that it becomes {-x-dx, -y-dy}

&#8202;

#### `get_camera()`
- Gets the current(inversed) drawing coordinate offset.
- Returns:
  - camera_x
  - camera_y

&#8202;

#### `clip(x, y, w, h)`
- Sets the clip area so that nothing gets drawn outside of it.

&#8202;

#### `get_clip()`
- Gets the current clip area.
- Returns:
  - clip_x
  - clip_y
  - clip_w
  - clip_h

&#8202;

#### `color(i)`
- Sets the color to use for drawing functions to `i`.
- `i` is an index to a color in the currently used palette.

&#8202;

#### `pal(ca, cb, [flip_level = false])`
- Swaps the color `ca` with the color `cb` in the following draw operations. (if `flip_level` is `false`)
- `ca` and `cb` are both indexes in the currently used palette.
- If `flip_level` is true, the swap will only take effect on display.

&#8202;

#### `clear([c = 0])`
- Clears the screen with the color `c`.

&#8202;

#### `cls([c = 0])`
- Alias for `clear(c)`.

&#8202;

#### `rectfill(xa, ya, xb, yb, [c])`
- Draws a filled rectangle.

&#8202;

#### `rect(xa, ya, xb, yb, [c])`
- Draws an empty rectangle.

&#8202;

#### `circfill(x, y, r, [c])`
- Draws a filled circle.

&#8202;

#### `circ(x, y, r, [c])`
- Draws an empty circle.

&#8202;

#### `trifill(xa, ya, xb, yb, xc, yc, [c])`
- Draws a filled triangle.

&#8202;

#### `tri(xa, ya, xb, yb, xc, yc, [c])`
- Draws an empty triangle.

&#8202;

#### `line(xa, ya, xb, yb, [c])`
- Draws a line.

&#8202;

#### `pset(x, y, [c])`
- Sets the color of one pixel.

&#8202;

#### `str_px_width(str)`
- Returns the width in pixels of the string `str` as it would be rendered.
- Font defaults to the current active font.

&#8202;

#### `print(str, x, y, [c])`
- Draws the string `str` on the screen at the coordinates {x; y}.

&#8202;

#### `printp(a, b, c, d)`
- Defines the print pattern for `pprint(...)`.
- `a, b, c, d` are to be defined as such:
```lua
  printp( 0x3330,
          0x3130,
          0x3230,
          0x3330 )
```
- The text will be drawn multiple times, with offsets according to the numbers' positions on the pattern, with the colors defined in `printp_color(...)`. 2 will be drawn on top of 3, and 1 will be drawn on top of 2.

&#8202;

#### `printp_color(c1, c2, c3)`
- Sets the colors for `pprint(...)`.

&#8202;

#### `pprint(str, x, y, c1, c2, c3)`
- Draw text with the pattern defined by the last `printp(...)` call.

&#8202;

### Maths

#### `cos(a)`
- Returns the cosine of `a` as a turn-based angle.

&#8202;

#### `sin(a)`
- Returns the sine of `a` as a turn-based angle.

&#8202;

#### `atan2(x, y)`
- Converts {`x`; `y`} as an angle from 0 to 1. Returns that angle.

&#8202;

#### `lerp(a, b, i)`
- Returns the linear interpolation from `a` to `b` with the parameter `i`.
- For the intended use, `i` should be between `0` and `1`. However it is not limited to those value.

&#8202;

#### `flr(a)`
- Returns the closest integer that is equal or below `a`.

&#8202;

#### `ceil(a)`
- Returns the closest integer that is equal or above `a`.

&#8202;

#### `round(a)`
- Returns the closest integer to `a`.

&#8202;

#### `sgn(a)`
- Returns `1` if `a` is positive.
- Returns `-1` if `a` is negative.
- Returns `0` if `a` is zero.

&#8202;

#### `sqr(a)`
- Returns `a * a`.

#### `cub(a)`
- Returns `a * a * a`.

#### `pow(a, b)`
- Returns the result of `a` to the power of `b`.
- `pow(a, 2)` is **much slower** than `sqr(a)`.

&#8202;

#### `sqrt(a)`
- Returns the square root of `a`.

&#8202;

#### `abs(a)`
- Returns the absolute (positive) value of `a`.

&#8202;

#### `min(a, b)`
- Returns the lower value between `a` and `b`.

&#8202;

#### `max(a, b)`
- Returns the higher value between `a` and `b`.

&#8202;

#### `mid(a, b, c)`
- Returns the middle value between `a`, `b` and `c`.
- `mid(1, 3, 2)` will return `2`.

&#8202;

#### `angle_diff(a1, a2)`
- Returns the difference between the turn-based angle `a1` and the turn-based angle `a2`.

&#8202;

#### `dist(x1, y1, [x2, y2])`
- If x2 and y2 are set, returns the distance between {x1; y1} and {x2; y2}.
- Otherwise, returns the distance between {0; 0} and {x1; y1}.

&#8202;

#### `sqrdist(x, y)`
- Returns the squared distance between {0; 0} and {x1; y1}.
- Is faster than `dist(...)`.

&#8202;

#### `srand(seed)`
- Sets the seed for the random number generation.

&#8202;

#### `raw_rnd()`
- Returns a random number.
- Always returns an integer.

&#8202;

#### `rnd(n)`
- Returns a random decimal number between `0` *(included)* and `n` *(excluded)*.

&#8202;

#### `irnd(n)`
- Returns a random integer number between `0` *(included)* and `n` *(excluded)*.

&#8202;

#### `pick(tab)`
- Takes an ordered table *(with linear numeral keys)* as parameter.
- Returns a random element from the table.

&#8202;

### Time

#### `t()`
- Returns the time in seconds since the program's start-up.

&#8202;

#### `time()`
- Alias for `t()`.

&#8202;

#### `dt()`
- Returns the time between this frame and the previous one.

&#8202;

#### `delta_time()`
- Alias for `dt()`.

&#8202;

#### `freeze(sec)`
- Stops the program for `sec` seconds.
- Using this function will **not** affect `dt()`.

&#8202;

#### `sys_ltime()`
- Get the system time in the local time zone.
- Returns, in this order:
  - seconds (`0 - 59`)
  - minutes (`0 - 59`)
  - hour (`0 - 23`)
  - day (`1 - 31`)
  - month (`1 - 12`)
  - year (full year)
  - week day (`1 - 7`)

&#8202;

#### `sys_gtime()`
- Get the system time as UTC time.
- Returns, in this order:
  - seconds (`0 - 59`)
  - minutes (`0 - 59`)
  - hour (`0 - 23`)
  - day (`1 - 31`)
  - month (`1 - 12`)
  - year (full year)
  - week day (`1 - 7`)

&#8202;


### Utility

#### `all(ar)`
- To use with `for` to iterate through the elements of the ordered table `ar`.
- e.g:
```lua
local tab = {1, 2, 3}
for n in all(tab) do
  print(n)
end
-- > 1   2   3
```

&#8202;

#### `del(ar, val)`
- Finds and removes the first occurence of `val` in the ordered table `ar`.
- If `ar` does not contain `val`, nothing happens.

&#8202;

#### `del_at(ar, n)`
- Removes the item at position `n` in the ordered table `ar`.

&#8202;

#### `add(ar, v)`
- Adds the item `v` to the end of the ordered table `ar`.

&#8202;

#### `sort(ar)`
- Sorts the ordered table `ar`.

&#8202;

#### `merge_tables(dst, src)`
- Copies all the keys from the table `src` into the table `dst`.
- Returns `dst`.

&#8202;

#### `copy_table(tab, [deep])`
- Returns a copy of the table `tab`.
- If `deep` is `true`, the copy will have copies of any tables found inside `tab` and so will those.
- /!\ Avoid setting `deep` to `true` when operating on tables linking to other tables in your structure, especially if you're working with double-linked tables, as that would create an infinite loop.

&#8202;



]]

local nstr = str:gsub("#### `(.-)`(.-)\n\n&#8202;", "['%1'] = [[#### `%1`%2]],")
local nstrb = str:gsub("#### `(.-)`(.-)\n\n&#8202;\n", "'%1',")
write_clipboard(nstr..nstrb)
end





do ---- Game data + function data

  game_info = {
    _title         = "<Set a title>",
    _description   = "<Set a short description>",
    _player_glyph  = 0x01,
    _controls      = {},
    _controls_list = {},
    _cursor_info   = nil,
    _id            = nil,
    _published     = false
  }

  functions = {
    {
      name = "_init",
      def  = "_init(difficulty)",
      code = "",
      args = { "difficulty" }
    },
    {
      name = "_update",
      def  = "_update()",
      code = "",
      args = {}
    },
    {
      name = "_draw",
      def  = "_draw()",
      code = "",
      args = {}
    }
  }

  function_list = {
    "_init(difficulty)",
    "_update()",
    "_draw()"
  }

  function_names = {}
  for _,f in pairs(functions) do function_names[f.name] = f end

  cur_function = functions[1]

end


do ---- Main screen

  local min_side = 256
  local pal_x, pal_y = 0,0
  local gly_x, gly_y = 0,0
  local inf_x, inf_y = 0,0
  function __load()
    local w,h = window_size()
    local scale = ceil(min(w, h) / min_side)
    screen_resizeable(true, 8, on_resize)
  end
  love.load = __load

--  local first_update
  function __update()
--    if not first_update then
      on_resize()
--      first_update = true
--    end
  
    update_palette()
    update_glyphgrid()
    castle.uiupdate = ui_panel
  end
  love.update = __update

  function __draw()
    cls()
    
    if message and (t() - message_t) < 4 then
      local y = min(1.5 - abs(t() - message_t - 2), 0) * 32
      print(message, (screen_w() - str_px_width(message))/2, y, 28)
    end
    
    draw_glyphgrid()
    draw_palette()
    
    draw_info()
    
    draw_cursor()
  end
  love.draw = __draw

  local pal_color_a, pal_color_b = 29, 27
  function update_palette()
    local mx,my = sugar.input.btnv("cur_x"), sugar.input.btnv("cur_y")
    local lb,rb = sugar.input.btn("cur_lb"), sugar.input.btn("cur_rb")

    if (lb or rb) and point_in_rect(mx, my, pal_x, pal_y, pal_x+6*16, pal_y+5*16) then
      local i = flr((mx-pal_x)/16) + flr((my-pal_y)/16)*6
      
      if lb then
        pal_color_a = i
      end
      
      if rb then
        pal_color_b = i
      end
    end
  end

  function draw_palette()
    local x,y = pal_x, pal_y
    local mx, my = sugar.input.btnv("cur_x"), sugar.input.btnv("cur_y")
    
    for j = 0,4 do
      for i = 0,5 do
        local xx,yy = x+i*16, y+j*16
        rectfill(xx, yy, xx+15, yy+15, j*6+i)
      end
    end
    
    rect(x-1, y-1, x + 6*16, y + 5*16, 29)
    
    printp(0x2220, 0x2120, 0x2220, 0x0)
    printp_color(29, 0, 0)
    
    local xx, yy = pal_x + 1, pal_y + 5*16 + 3
    rect(xx-1, yy-1, xx+16, yy+16, 29)
    rectfill(xx, yy, xx+15, yy+15, pal_color_a)
    pprint(pal_color_a, xx-1, yy-4)
    print("A", xx + 17, yy-1, 29)
    
    xx = pal_x + 5*16 - 1
    rect(xx-1, yy-1, xx+16, yy+16, 29)
    rectfill(xx, yy, xx+15, yy+15, pal_color_b)
    pprint(pal_color_b, xx-1, yy-4)
    print("B", xx - str_px_width("B") - 2, yy-1, 29)
    
    
    if not point_in_rect(mx, my, x, y, x+6*16, y+5*16) then
      return
    end
    
    local n = flr((mx-x)/16) + flr((my-y)/16)*6
    local xx,yy = flr((mx-x)/16)*16+x, flr((my-y)/16)*16+y
    rect(xx-1, yy-1, xx+16, yy+16, 29)
    
    pprint(n, xx-1, yy-4)
  end

  local glyph_selected = 0
  local glyph_hovered
  function update_glyphgrid()
    local mx,my = sugar.input.btnv("cur_x"), sugar.input.btnv("cur_y")
    local lb = sugar.input.btn("cur_lb")
    
    if point_in_rect(mx, my, gly_x, gly_y, gly_x+16*17, gly_y+16*17) then
      glyph_hovered = flr((my-gly_y)/17)*16 + flr((mx-gly_x)/17)
      
      if lb then
        glyph_selected = glyph_hovered
      end
    else
      glyph_hovered = nil
    end
  end
  
  local hex = {[0]='0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'}
  function draw_glyphgrid()
    local x,y = gly_x, gly_y
    local mx, my = sugar.input.btnv("cur_x"), sugar.input.btnv("cur_y")
    
    pal(1, pal_color_a)
    pal(2, pal_color_b)
    
    for j = 0,15 do
      for i = 0,15 do
        spr(j*16+i, x + i*17, y + j*17)
      end
    end
    
    rect(x-2, y-2, x + 16*17, y+16*17, 29)
    
    if glyph_hovered then
      local xx = x + (glyph_hovered % 16)*17
      local yy = y + flr(glyph_hovered / 16)*17
      
      rect(xx-2, yy-2, xx+17, yy+17, 28)
      
      local xx, yy = x, y + 16*17 + 4
      spr(glyph_hovered, xx, yy)
      rect(xx-2, yy-2, xx+17, yy+17, 28)
      
      local str = "0x"..hex[flr(glyph_hovered/16)]..hex[glyph_hovered%16].." ("..glyph_hovered..")"
      print(str, xx + 19, yy-1, 29)
    end
        
    if glyph_selected then
      local xx = x + (glyph_selected % 16)*17
      local yy = y + flr(glyph_selected / 16)*17
      
      rect(xx-2, yy-2, xx+17, yy+17, 29)
      
      local xx, yy = x + 15*17, y + 16*17 + 4
      spr(glyph_selected, xx, yy)
      rect(xx-2, yy-2, xx+17, yy+17, 29)
      
      local str = "("..glyph_selected..") 0x"..hex[flr(glyph_selected/16)]..hex[glyph_selected%16]
      print(str, xx - str_px_width(str) - 3, yy-1, 29)
    end

    pal(1, 1)
    pal(2, 2)
  end

  function draw_info()
    -- player glyph and cursor render
    
    local x,y = inf_x, inf_y
    
    local str = "Player glyph: "
    print(str, x, y)
    x = x + str_px_width(str)
    pal(1,29)
    pal(2,27)
    spr(game_info._player_glyph, x, y)
    
    if game_info._cursor_info then
      x = inf_x
      y = y + 16
      local str = "Cursor: "
      print(str, x, y)
      x = x + str_px_width(str) + 8
      y = y + 8
      
      circ(x, y, 8, 29)
      
      local d = game_info._cursor_info
      
      if d.outline then
        pal(1, d.outline)
        pal(2, d.outline)
        aspr(d.glyph, x-1, y, d.angle, 1, 1, d.point_x/16, d.point_y/16)
        aspr(d.glyph, x+1, y, d.angle, 1, 1, d.point_x/16, d.point_y/16)
        aspr(d.glyph, x, y-1, d.angle, 1, 1, d.point_x/16, d.point_y/16)
        aspr(d.glyph, x, y+1, d.angle, 1, 1, d.point_x/16, d.point_y/16)
      end
      
      pal(1, d.color_a)
      pal(2, d.color_b)
      aspr(d.glyph, x, y, d.angle, 1, 1, d.point_x/16, d.point_y/16)
    end
    
    pal(1,1)
    pal(2,2)
  end
  
  function draw_cursor()
    palt(0, false)
    palt(16, true)
    spritesheet("controls")
    
    local mx, my = sugar.input.btnv("cur_x"), sugar.input.btnv("cur_y")
    if sugar.input.btn("cur_lb") then
      spr(51, mx, my)
    else
      spr(50, mx, my)
    end
    
    spritesheet("glyphs")
    palt(0, true)
    palt(16, false)
  end

  function on_resize()
    local w,h = sugar.gfx.window_size()
    
    local scale_a = flr(h / 400)
    local scale_b = flr(w / 400)
    
    if scale_a >= scale_b then
      if scale_a ~= screen_scale() then
        screen_resizeable(true, scale_a, on_resize)
      end
      
      local w,h = sugar.gfx.screen_size()
      
      gly_x = w/2 - 128
      gly_y = 8 + 16
      
      pal_x = w - 132 -- w/2 - 48
      pal_y = h - 112
      
      inf_x = 40
      inf_y = h - 112
    else
      if scale_b ~= screen_scale() then
        screen_resizeable(true, scale_b, on_resize)
      end
      
      local w,h = sugar.gfx.screen_size()
      
      gly_x = 8
      gly_y = h/2 - 144 + 6
      
      pal_x = w - 100
      pal_y = h - 112 -- h/2 - 58 + 6
      
      inf_x = w - 116
      inf_y = 24
    end
  end

end


do ---- Game saving + loading

  local user_info = castle.user.isLoggedIn and castle.user.getMe()

  network.async(function()
    log("Retrieving user games...", "O")
    user_registry = castle.storage.get("user_registry") or {}
    log("Done retrieving user games!", "O")
  end)

  function load_game(id, from_user)
    network.async(function()
      local data = from_user and castle.storage.get("game_"..id) or castle.storage.getGlobal("game_"..id)
      
      if not data then
        r_log("Loading game "..id.." failed.")
        return
      end
      
      game_info = data.game_info
      functions = data.functions
      
      function_list = {}
      for _,f in ipairs(functions) do
        add(function_list, f.ind..f.def)
      end
      
      function_names = {}
      for _,f in pairs(functions) do
        function_names[f.name] = f
      end
      
      cur_function = functions[1]
      
      log("Loaded "..game_info._title, "O")
      new_message("Loaded "..game_info._title)
    end)
  end

  function save_game()
    local data = {}
    
    local first_time = (game_info._id == nil)
    if first_time then
      game_info._id = gen_game_id()
    end
    
    data.game_info = game_info
    data.functions = functions
    
    local info = {
      title     = game_info._title,
      author    = user_info.username,
      glyph     = game_info._player_glyph,
      published = game_info._published
    }
    
    local reg_data = {
      title     = game_info._title,
      id        = game_info._id,
      published = game_info._published,
      date      = os.time()
    }
    
    network.async(function()
      user_registry = castle.storage.get("user_registry") or {}

      if first_time then
        add(user_registry, reg_data)
      else
        local b
        for i,d in pairs(user_registry) do
          if d.id == reg_data.id then
            user_registry[i] = reg_data
            b = true
            break
          end
        end
        
        if not b then
          log("Game had an ID but couldn't be found in storage data.", "?")
          add(user_reg, reg_data)
        end
      end
      
      castle.storage.set("user_registry", user_registry)
    end)
    
    network.async(castle.storage.setGlobal, nil, "info_"..game_info._id, info)
    network.async(castle.storage.setGlobal, nil, "game_"..game_info._id, data)
    network.async(castle.storage.set, nil, "game_"..game_info._id, data)
    
    log("Saved the current game.", "O")
    new_message("Saved "..game_info._title)
  end

  function delete_game(id)
    network.async(function()
      user_registry = castle.storage.get("user_registry") or {}

      for i,d in pairs(user_registry) do
        if d.id == id then
          del_at(user_registry, i)
          break
        end
      end
      
      castle.storage.set("user_registry", user_registry)
    end)
    
    network.async(castle.storage.setGlobal, nil, "info_"..id, nil)
    network.async(castle.storage.setGlobal, nil, "game_"..id, nil)
    network.async(castle.storage.set, nil, "game_"..id, nil)
    
    if id == game_info._id then
      game_info._id = nil
    end
  end

  function gen_game_id()
    local now = {sys_gtime()}
    
    local str = ""
    for _,v in ipairs(now) do
      str = str..v
    end
    
    str = str..user_info.username..raw_rnd()
    
    return str
  end

end


do ---- Game compiling + testing
  local user_env
  
  function test_game()
    if testing then
      stop_testing()
    end

    local env = getfenv(1)
    env_save = copy_table(env)
    
    define_user_env()
    
    for _, f in ipairs(functions) do
      compile_foo(f)
    end
    
    for k, v in pairs(game_info) do
      if type(v) == "table" then
        local vc = copy_table(v)
        env[k] = vc
        user_env[k] = vc
      else
        env[k] = v
        user_env[k] = v
      end
    end
    
    testing = true
    
    runtime_error = nil

    love.update = new_love.update
    love.draw = new_love.draw
    
    screen_resizeable(false)
    screen_resize(256, 208)

    new_love.load("yes")
    
    log("Now testing.", "O")
  end

  function stop_testing()
    if not testing then
      return
    end
    
    testing = false
    
    screen_resizeable(true, 8, on_resize)
    on_resize()
    
    love.update = __update
    love.draw = __draw
    
    castle.uiupdate = ui_panel
    
    log("No longer testing.", "O")
  end

  function compile_foo(foo)
    local code = "function "..foo.def.." "..foo.code.." end"
    
    local env = getfenv(1)
    
    local comp, err = load(code, nil, "t", user_env)
    compile_error = err
    
    if err then
      log(foo.def.." compilation failed: "..err, "X")
      new_message("Compilation failed.")
    else
      comp()
      env[foo.name] = user_env[foo.name]
      log("Compiled "..foo.def.."!", "O")
      new_message("Compiled "..foo.def.." successfully!")
    end
  end

  catch_logs(function(str)
    if not runtime_error and str:sub(1,3) == "ERR" then
      runtime_error = str:gsub("\n", "`\r\n- `")
    end
  end)

  function define_user_env()
    user_env = {
      unpack          = unpack,
      select          = select,
      pairs           = pairs,
      ipairs          = ipairs,
      table           = table,
      string          = string,
      type            = type,
      getmetatable    = getmetatable,
      setmetatable    = setmetatable,
      error           = error,
      tostring        = tostring,
      tonumber        = tonumber,
      bit             = bit,
      network         = network,
      
      log             = log,
      w_log           = w_log,
      r_log           = r_log,
      assert          = assert,
      write_clipboard = write_clipboard,
      read_clipboard  = read_clipboard,
      screen_size     = screen_size,
      screen_w        = screen_w,
      screen_h        = screen_h,
      camera          = camera,
      camera_move     = camera_move,
      get_camera      = get_camera,
      clip            = clip,
      get_clip        = get_clip,
      color           = color,
      pal             = pal,
      clear           = clear,
      cls             = cls,
      rectfill        = rectfill,
      rect            = rect,
      circfill        = circfill,
      circ            = circ,
      trifill         = trifill,
      tri             = tri,
      line            = line,
      pset            = pset,
      btn             = btn,
      btnp            = btnp,
      btnr            = btnr,
      btnv            = btnv,
      cos             = cos,
      sin             = sin,
      atan2           = atan2,
      angle_diff      = angle_diff,
      dist            = dist,
      sqrdist         = sqrdist,
      lerp            = lerp,
      sqr             = sqr,
      cub             = cub,
      pow             = pow,
      sqrt            = sqrt,
      flr             = flr,
      round           = round,
      ceil            = ceil,
      abs             = abs,
      sgn             = sgn,
      min             = min,
      max             = max,
      mid             = mid,
      srand           = srand,
      raw_rnd         = raw_rnd,
      rnd             = rnd,
      irnd            = irnd,
      pick            = pick,
      str_px_width    = str_px_width,
      print           = print,
      printp          = printp,
      printp_color    = printp_color,
      pprint          = pprint,
      t               = t,
      time            = time,
      dt              = dt,
      delta_time      = delta_time,
      sys_ltime       = sys_ltime,
      sys_gtime       = sys_gtime,
      freeze          = freeze,
      all             = all,
      del             = del,
      del_at          = del_at,
      add             = add,
      sort            = sort,
      merge_tables    = merge_tables,
      copy_table      = copy_table,
      
      gameover        = gameover,
      glyph           = glyph,
      outlined_glyph  = outlined_glyph,
      screenshot      = screenshot,
      screenshake     = screenshake,
    }
    
    return user_env
  end
  define_user_env()

end


do ---- Function editing

  function find_foo(def)
    for _, d in pairs(functions) do
      if d.def == def then
        return d
      end
    end
  end

  function new_foo()
    local name, i, b = "new_function", 1, false
    while not b do
      for _, f in pairs(functions) do
        if f.name == name then
          i = i+1
          name = "new_function"..i
          goto try_again
        end
      end

      b = true
      ::try_again::
    end

    local nf = {
      name = name,
      def  = name.."()",
      code = "",
      args = {}
    }

    add(functions, nf)
    add(function_list, nf.def)
    return nf
  end

  function update_def(foo)
    local old_def = foo.def

    if #foo.args == 0 then
      foo.def = foo.name.."()"
    else
      foo.def = foo.name.."("
      for _,arg in ipairs(foo.args) do
        foo.def = foo.def..arg..", "
      end

      foo.def = foo.def:sub(1, #foo.def-2)..")"
    end

    for i, d in pairs(function_list) do
      if d == old_def then
        function_list[i] = foo.def
      end
    end
  end

  function delete_foo(foo)
    log("Deleting function "..foo.def, "O")
          
    del(function_list, foo.def)
    del(functions, foo)
    function_names[foo.name] = nil
    foo = functions[1]
  end

end


do ---- Message / notification

  message_t, message = -99
  function new_message(str)
    message_t = t()
    message = str
  end

end


--for k,v in pairs(os.date("*t", os.time())) do
--  log(k.." : "..v)
--end

do ---- UI definitions

--  local tab, tabs = "Projects", {"Projects", "Game Info", "Code", --[["Play"]]}

  local ui = castle.ui
  function castle.uiupdate()

    ui.tabs("mainTabs", function()
      ui.tab("Project", project_panel)
      ui.tab("Game Info", info_editor)
      ui.tab("Code", function_editor)
--      ui.tab("Play", testing_ui)
    end)

--    tab = ui.radioButtonGroup("Fake Tabs", tab, tabs, {hideLabel = true})
--    
--    
--    
--    if tab == "Projects" then
--      project_panel()
--    elseif tab == "Game Info" then
--      info_editor()
--    elseif tab == "Code" then
--      function_editor()
--    --elseif tab == "Play" then
--    --  testing_ui()
--    end
    
    ui.markdown("&#160;")
    ui.box("testing_ui", { borderTop = "3px dotted white", justifyItems = "center", borderRadius = 16, margin = 1, padding = 3 }, testing_ui)
    
  --  ui.markdown("~~~")
  --  ui_code = ui.codeEditor("Ui", ui_code)
  --  if compile_soon then compile_soon = false compile() end
  --  if ui.button("Compile") then compile_soon = true end
  --  if ui.button("Open") then load_saved() end
  end
  ui_panel = castle.uiupdate

  do -- setting castle.uiupdate in stone (figuratively)
    local s_castle = castle
    castle = setmetatable({}, {
      __index = s_castle,
      __newindex = function(t, k, v)
        if k ~= "uiupdate" then
          s_castle[k] = v
        end
      end
    })
    
    function remove_editor_panel()
      castle = s_castle
      castle.uiupdate = nil
    end
  end


  -- project panel

  local time_units = {"second", "minute", "hour", "day", "month", "year"}
  local time_keys = {"sec", "min", "hour", "day", "month", "year"}
  local deleting_project = {}
  function project_panel()
    ui.markdown("Current game:")
    
    ui.box("current_game_box", { borderLeft = "3px dotted white", borderRadius = 16, margin = 1, padding = 3 }, function()
      ui.markdown("***"..game_info._title.."***\r\n\r\n*`"..(game_info._id or "Save to generate an ID").."`*\r\n\r\n*"..(game_info._published and "Published" or "Not published").."*")
      if ui.button("[Save game]") then
        save_game()
      end
    end)

    ui.markdown("&#160;\r\n\r\nMy games:")
    
    if not user_registry then
      ui.markdown("*Loading data...*")
    elseif #user_registry == 0 then
      ui.markdown("*This account has no saved games.*")
    else
      for i,info in ipairs(user_registry) do

        ui.box("game_box_"..i, { borderLeft = "3px dotted white", borderRadius = 16, margin = 1, padding = 3 }, function()
          ui.markdown("***"..info.title.."***\r\n\r\n*`"..info.id.."`*\r\n\r\n*"..(info.published and "Published" or "Not published").."*")
          
          local d, str = os.date("*t", os.time() - (info.date or 0))
          for i = 6, 1, -1 do
            local diff = d[time_keys[i]]
            if diff > 0 then
              str = "*Saved "..diff.." "..time_units[i]..(diff > 1 and "s" or "").." ago.*"
            end
          end
          
          ui.markdown(str or "*Saved just now.*")
          
          
          if ui.button("[Load game]") then
            load_game(info.id, true)
          end
          
          if deleting_project[info.id] then
            ui.markdown("**Are you sure you want to delete this game?**")
            ui.box("delete_project_comfirm"..info.id, { flexDirection = "row"}, function()
              if ui.button("Yes", { kind = "danger" }) then
                delete_game(info.id)
                deleting_project[info.id] = nil
              end
            
              if ui.button("No") then
                deleting_project[info.id] = nil
              end
            end)
          else
            if ui.button("[Delete game]", { kind = "danger" }) then
              deleting_project[info.id] = true
            end
          end
        end)
      end
    end
    
  end


  -- info editor

  local allowed_inputs = {"[x]", "right", "down", "left", "up", "A", "B", "cur_x", "cur_y", "cur_lb", "cur_rb" }

  function info_editor()
    game_info._title = ui.textInput("Title", game_info._title)
    game_info._description = ui.textInput("Description", game_info._description)
    
    game_info._player_glyph = flr(ui.slider("Player glyph", game_info._player_glyph, 0, 255, {step = 1}))

    ui.section("Controls", controls_edit)

    cursor_edit()
  end

  function controls_edit()
    local list, i = game_info._controls_list, 0
    repeat
      i = i + 1
      local ctrl = list[i] or {}
      
      ui.box("controlsBox"..i, { flexDirection = "row", flexWrap = "wrap", border = "2px dotted grey", borderRadius = 16, margin = 1, padding = 3 }, function()
        local inputs = ctrl.inputs or {}
      
        local j = 0
        repeat
          j = j + 1
          
          local nv = ui.dropdown("input"..i..":"..j, inputs[j], allowed_inputs, {hideLabel = true, placeholder = "[new input]"})
          
          local ov = inputs[j]
          if nv ~= ov then
            if ov then
              game_info._controls[ov] = nil
              add(allowed_inputs, ov)
            end
          
            if nv == "[x]" then
              inputs[j] = nil
            else
              del(allowed_inputs, nv)
            
              if not ctrl.inputs then
                ctrl.inputs = inputs
                
                if not list[i] then list[i] = ctrl end
              end
              
              game_info._controls[nv] = ctrl.description
              
              inputs[j] = nv
            end
          end
          
          ui.markdown("&#160;")
        until not inputs[j]
        
        local nv = ui.textInput("control"..i, ctrl.description or "", {hideLabel = true, placeholder = "[does what?]"})
        
        if nv ~= ctrl.description then
          for _, inp in pairs(inputs) do
            game_info._controls[inp] = nv
          end
        
          ctrl.description = nv
        end
      end)
    
    until not list[i]
  end

  function cursor_edit()
    if ui.checkbox("Use custom cursor", game_info._cursor_info ~= nil) then
      ui.section("Cursor Info", { defaultOpen = true }, function()
        if not game_info._cursor_info then
          game_info._cursor_info = {
            glyph = 0x10,
            color_a = 29,
            color_b = 27,
            outline = 0,
            point_x = 8,
            point_y = 8,
            angle = 0
          }
        end
        
        local info = game_info._cursor_info
        info.glyph = flr(ui.slider("Glyph", info.glyph, 0, 255, {step = 1}))
        info.color_a = flr(ui.slider("Color A", info.color_a, 0, 29, {step = 1}))
        info.color_b = flr(ui.slider("Color B", info.color_b, 0, 29, {step = 1}))

        if ui.checkbox("Outline", info.outline ~= nil) then
          info.outline = info.outline or 0
          info.outline = flr(ui.slider("Outline color", info.outline, 0, 29, {step = 1}))
        else
          info.outline = nil
        end

        info.point_x = ui.slider("Point X", info.point_x, 0, 16, {step = 1})
        info.point_y = ui.slider("Point Y", info.point_y, 0, 16, {step = 1})
        info.angle = ui.slider("Angle", info.angle, 0, 1, {step = 0.001})
      end)
    else
      game_info._cursor_info = nil
    end
  end


  -- code editor

  local deleting_function
  local essential_functions = { _init = true, _update = true, _draw = true }
  local function_name = "_init"
  local name_issue
  function function_editor()
    local chosen = function_picker()-- ui.dropdown("Function", cur_function.def, function_list)
    if chosen ~= cur_function.def then
      if chosen == "[+] new function" then
        cur_function = new_foo()
      else
        cur_function = find_foo(chosen)
      end
      
      function_name = cur_function.name
      deleting_function = nil
    end
    
    ui.markdown("`name`")
    
    if essential_functions[cur_function.name] then
      ui.markdown(cur_function.name.." *-- cannot be changed*")
    else
      local nv = ui.textInput("name", function_name, {hideLabel = true})
      if nv ~= function_name then
        if function_names[nv] and nv ~= cur_function.name then -- function name already exists
          name_issue = "Function name already exists."
        elseif nv == "" then
          name_issue = "Function name cannot be empty."
        elseif nv:find("%s") then
          name_issue = "Function name may not contain spaces."
        else
          name_issue = nil
          cur_function.name = nv
          update_def(cur_function)
        end
        
        function_name = nv
      end
      
      if name_issue then
        ui.markdown("`Error: "..name_issue.."`")
      end
    end
    
    ui.markdown("`arguments`")
    ui.box("argumentsBox", { flexDirection = "row", flexWrap = "wrap", marginLeft = 3 }, function()
      local args, i = cur_function.args, 0
      repeat
        i = i + 1
        local nv
        
        ui.box("argbox"..i, {width = 0.45, padding = 1}, function()
          nv = ui.textInput( "argument"..i, args[i] or "", {hideLabel = true})
        end)
        
        if nv == "" and args[i] then
          del_at(args, i)
          update_def(cur_function)
          i = i - 1
        elseif nv ~= "" and nv ~= args[i] then
          args[i] = nv
          update_def(cur_function)
        end
      until not args[i]
    end)
    
    ui.markdown("`function "..cur_function.def.."`")
    cur_function.code = ui.codeEditor("code", cur_function.code, { hideLabel = true })
    ui.markdown("`end`")
    
    ui.markdown("&#160;")
    
    if compile_error then
      ui.markdown("`Compile error:`")
      ui.markdown("`"..compile_error.."`")
    end

    if ui.button("Compile function") then
      compile_foo(cur_function)
    end
    
    
    if not essential_functions[cur_function.name] then
      if deleting_function then
        ui.markdown("**Are you sure you want to delete "..cur_function.def.."?**")
        ui.box("delete_function_comfirm"..cur_function.name, { flexDirection = "row"}, function()
          if ui.button("Yes", { kind = "danger" }) then
            delete_foo(cur_function)
            cur_function = functions[1]
            deleting_function = nil
          end
        
          if ui.button("No") then
            deleting_function = nil
          end
        end)
      else
        if ui.button("/!\\ Remove function", {kind = "danger"}) then
          deleting_function = true
        end
      end
    end

--    ui.markdown("&#160;\r\n\r\n---\r\n\r\n&#160;")
--    if ui.button("Open Documentation") then
--      love.system.openURL("https://github.com/TRASEVOL-DOG/Collection/blob/master/game_editor.md#game-editor-api-documentation")
--    end
    
    ui.markdown("&#160;")
    ui.section("Complete API", doc_browser)
  end
  
  
  local indent = "|    "
  function function_picker()
    local chosen = ui.radioButtonGroup("Functions", (cur_function.ind or "")..cur_function.def, function_list)
    
    ui.box("function_mover", {flexDirection = "row", justifyContent = "space-between"}, function()
      local up, down, left, right
      
      ui.box("foo_up",    { width = 0.24 }, function() up = ui.button("▲") end)
      ui.box("foo_down",  { width = 0.24 }, function() down = ui.button("▼") end)
      ui.box("foo_left",  { width = 0.24 }, function() left = ui.button("◀") end)
      ui.box("foo_right", { width = 0.24 }, function() right = ui.button("▶") end)

      if up or down or left or right then
        local i
        local ref = (cur_function.ind or "")..cur_function.def
        for j,v in ipairs(function_list) do
          if ref == v then
            i = j
            break
          end
        end
        
        if up and i > 1 then
          function_list[i-1], function_list[i] = function_list[i], function_list[i-1]
        elseif down and i < #function_list then
          function_list[i+1], function_list[i] = function_list[i], function_list[i+1]
        end
        
        if right then
          chosen = indent..chosen
          function_list[i] = chosen
          cur_function.ind = (cur_function.ind or "")..indent
        elseif left and chosen:sub(1,#indent) == indent then
          chosen = chosen:sub(#indent+1, #chosen)
          function_list[i] = chosen
          cur_function.ind = cur_function.ind:sub(#indent+1, #cur_function.ind)
        end
      end
      
    end)
    
    if ui.button("[+] new function") then
      return "[+] new function"
    end
    
    return chosen:gsub(indent, "")
  end

  
  do -- doc browser
    local cat = "Introduction"
    local foo
    
    local categories = {
      "Introduction",
      "Packages",
      "Debug",
      "Drawing",
      "Glyphs",
      "Text rendering",
      "Input",
      "Maths",
      "Time",
      "Utility",
      "Misc",
      "Gameplay"
    }
  
    local foo_names = {
      Packages = {
        "string",
        "table",
        "bit",
        "network",
      },
      
      Debug = {
'log(str, [prefix])',
'w_log(str)',
'r_log(str)',
'assert(condition, str)',
'write_clipboard(str)',
'read_clipboard()',
      },
      
      Drawing = {
'screen_size()',
'screen_w()',
'screen_h()',
'camera([x = 0, y = 0])',
'camera_move(dx, dy)',
'get_camera()',
'clip(x, y, w, h)',
'get_clip()',
'color(i)',
'pal(ca, cb, [flip_level = false])',
'clear([c = 0])',
'cls([c = 0])',
'rectfill(xa, ya, xb, yb, [c])',
'rect(xa, ya, xb, yb, [c])',
'circfill(x, y, r, [c])',
'circ(x, y, r, [c])',
'trifill(xa, ya, xb, yb, xc, yc, [c])',
'tri(xa, ya, xb, yb, xc, yc, [c])',
'line(xa, ya, xb, yb, [c])',
'pset(x, y, [c])',
      },
      
      Glyphs = {
'glyph(n, x, y, width, height, angle, color_a, color_b, [anchor_x = 8, anchor_y = 8])',
'outlined_glyph(n, x, y, width, height, angle, color_a, color_b, outline_color, [anchor_x = 8, anchor_y = 8])',
      },
      
      ["Text rendering"] = {
'str_px_width(str)',
'print(str, x, y, [c])',
'printp(a, b, c, d)',
'printp_color(c1, c2, c3)',
'pprint(str, x, y, c1, c2, c3)',
      },
      
      Input = {
'btn(input)',
'btnp(input)',
'btnr(input)',
'btnv(input)',
      },
      
      Maths = {
'cos(a)',
'sin(a)',
'atan2(x, y)',
'lerp(a, b, i)',
'flr(a)',
'ceil(a)',
'round(a)',
'sgn(a)',
'sqr(a)',
'cub(a)',
'pow(a, b)',
'sqrt(a)',
'abs(a)',
'min(a, b)',
'max(a, b)',
'mid(a, b, c)',
'angle_diff(a1, a2)',
'dist(x1, y1, [x2, y2])',
'sqrdist(x, y)',
'srand(seed)',
'raw_rnd()',
'rnd(n)',
'irnd(n)',
'pick(tab)',
      },
      
      Time = {
't()',
'time()',
'dt()',
'delta_time()',
'freeze(sec)',
'sys_ltime()',
'sys_gtime()',
      },
      
      Utility = {
'all(ar)',
'del(ar, val)',
'del_at(ar, n)',
'add(ar, v)',
'sort(ar)',
'merge_tables(dst, src)',
'copy_table(tab, [deep])',
      },
      
      Misc = {
        "type",
        "tostring",
        "tonumber",
        "getmetatable",
        "setmetatable",
      },
      
      Gameplay = {
'gameover(score, [stats])',
'screenshake(power)',
'screenshot()',
      }
    }
    
    local doc = {
introduction = [[The Collection Game Editor limits the base functions available to you for two reasons:

- Providing a simpler environment for you to make cool stuff with
- Making sure you don't break the environment

In consequence, most of the functions available to you come directly from Sugarcoat, while `love` and all its functions are banished. `castle` and its functions are also banished, as our game framework needs exclusivity over their features to function properly.

In addition to this, here are some quirks resulting from the design of the game framework and the use of Sugarcoat:

- The only assets you may use are the glyphs provided by the framework. You cannot use external assets. However you may use primitive drawing functions.
- You may only use the colors from the palette provided by the framework. When drawing glyphs or primitive shapes, you can use any color by passing its index in the palette.
- The game's resolution is fixed to 256x192 pixels.
- You may only use the inputs defined manually in the "Game Info" panel.]],
   
string = [[]],
table = [[]],
bit = [[]],
network = [[]],

['gameover(score, [stats])'] = [[### `gameover(score, [stats])`
- Ends the game.
- `score` is the player's final score. It should be between 0 *(terrible, player didn't even try)* and 100. *(perfect)*
- `stats` *(optional)* is a table of up-to-5 strings, to be displayed on the gameover. You may use this to give the player more information on how they did in the game.]],

['glyph(n, x, y, width, height, angle, color_a, color_b, [anchor_x = 8, anchor_y = 8])'] = [[### `glyph(n, x, y, width, height, angle, color_a, color_b, [anchor_x = 8, anchor_y = 8])`
- Draws the glyph `n` at the coordinates `x, y`, **stretched** to `width, height`, rotated by `angle` full turns, using `color_a` as main color and `color_b` as secondary color, centered on the point `anchor_x, anchor_y` on the glyph. *(in pixel coordinates, default is `8, 8`)*
- Every glyph's original size is 16x16.
- `color_b` is mostly used for anti-alias and details on the glyphs.
- `angle` is counted in *turns*, meaning `1` results in a full rotation, while `0.5` results in a half rotation. (180 degrees, Pi radians)]],

['outlined_glyph(n, x, y, width, height, angle, color_a, color_b, outline_color, [anchor_x = 8, anchor_y = 8])'] = [[### `outlined_glyph(n, x, y, width, height, angle, color_a, color_b, outline_color, [anchor_x = 8, anchor_y = 8])`
- Same as `glyph(...)` above, except a 1-pixel-thick outline is drawn around the glyph, using the color `outline_color`.]],

['screenshot()'] = [[### `screenshot()`
- Saves a screenshot of the game to `%appdata%\LOVE\Castle` if on Windows, and to `/Users/user/Library/Application Support/LOVE/Castle` if on Mac.
- The file's name will be `[game title].png`.]],

['screenshake(power)'] = [[### `screenshake(power)`
- Shakes the screen with `power` intensity.
- The intensity will be affected by the 'screenshake' user setting. (accessible in the game's pause panel once published)]],

['btn(input)'] = [[### `btn(input)`
- Returns the state (`true`/`false`) of the input `input`.
- `input` has to have been set in the "Game Info" panel.
- Correspondance between kayboard and controller is automated. Both will trigger the same defined inputs.
- You may use the following inputs: (as are available in the "Game Info" panel)
  - `right`
  - `down`
  - `left`
  - `up`
  - `A` *(Z or Shift on a keyboard)*
  - `B` *(X or Ctrl on a keyboard)*
  - `cur_x`
  - `cur_y`
  - `cur_lb`
  - `cur_rb`]],

['btnp(input)'] = [[### `btnp(input)`
- "btnp" is short for "button press".
- Returns whether the input `input` is active but wasn't during the previous frame.]],

['btnr(input)'] = [[### `btnr(input)`
- "btnr" is short for "button release".
- Returns whether the input `input` was active the previous frame but isn't anymore.]],

['btnv(input)'] = [[### `btnv(input)`
- "btnv" is short for "button value".
- Returns a decimal number representing the state of the input.
- Particularly useful for `cur_x` and `cur_y`: `btnv("cur_x")` will give you the X mouse coordinate for example.
- Simple button inputs *(keyboard keys for example)* will return 1 when pressed and 0 when not.]],


['log(str, [prefix])'] = [[### `log(str, [prefix])`
- Puts a new line in the log with the information 'str'.
- If `prefix` is set, prints it in front of `str` instead of the default prefix. (` . `)
- `prefix` can only be up to 3 characters.]],

['w_log(str)'] = [[### `w_log(str)`
- Puts a new **warning** line in the log with the information 'str'.]],

['r_log(str)'] = [[### `r_log(str)`
- Puts a new **error** line in the log with the information 'str'.]],

['assert(condition, str)'] = [[### `assert(condition, str)`
- Checks the condition and crashes if it isn't true. Logs and outputs the message 'str' on crash.]],

['write_clipboard(str)'] = [[### `write_clipboard(str)`
- Writes 'str' to the system clipboard.]],

['read_clipboard()'] = [[### `read_clipboard()`
- Reads the system clipboard.
- Returns the clipboard's content as a string.]],

['screen_size()'] = [[### `screen_size()`
- Returns:
  - the width of the screen resolution. *(always 256 here)*
  - the height of the screen resolution. *(always 192 here)*]],

['screen_w()'] = [[### `screen_w()`
- Returns the width of the screen resolution. *(always 256 here)*]],

['screen_h()'] = [[### `screen_h()`
- Returns the height of the screen resolution. *(always 192 here)*]],

['camera([x = 0, y = 0])'] = [[### `camera([x = 0, y = 0])`
- Sets a coordinate offset of {-x, -y} for the following draw operations.
- Calling `camera()` resets this.]],

['camera_move(dx, dy)'] = [[### `camera_move(dx, dy)`
- Offsets the coordinate offset so that it becomes {-x-dx, -y-dy}]],

['get_camera()'] = [[### `get_camera()`
- Gets the current(inversed) drawing coordinate offset.
- Returns:
  - camera_x
  - camera_y]],

['clip(x, y, w, h)'] = [[### `clip(x, y, w, h)`
- Sets the clip area so that nothing gets drawn outside of it.]],

['get_clip()'] = [[### `get_clip()`
- Gets the current clip area.
- Returns:
  - clip_x
  - clip_y
  - clip_w
  - clip_h]],

['color(i)'] = [[### `color(i)`
- Sets the color to use for drawing functions to `i`.
- `i` is an index to a color in the currently used palette.]],

['pal(ca, cb, [flip_level = false])'] = [[### `pal(ca, cb, [flip_level = false])`
- Swaps the color `ca` with the color `cb` in the following draw operations. (if `flip_level` is `false`)
- `ca` and `cb` are both indexes in the currently used palette.
- If `flip_level` is true, the swap will only take effect on display.]],

['clear([c = 0])'] = [[### `clear([c = 0])`
- Clears the screen with the color `c`.]],

['cls([c = 0])'] = [[### `cls([c = 0])`
- Alias for `clear(c)`.]],

['rectfill(xa, ya, xb, yb, [c])'] = [[### `rectfill(xa, ya, xb, yb, [c])`
- Draws a filled rectangle.]],

['rect(xa, ya, xb, yb, [c])'] = [[### `rect(xa, ya, xb, yb, [c])`
- Draws an empty rectangle.]],

['circfill(x, y, r, [c])'] = [[### `circfill(x, y, r, [c])`
- Draws a filled circle.]],

['circ(x, y, r, [c])'] = [[### `circ(x, y, r, [c])`
- Draws an empty circle.]],

['trifill(xa, ya, xb, yb, xc, yc, [c])'] = [[### `trifill(xa, ya, xb, yb, xc, yc, [c])`
- Draws a filled triangle.]],

['tri(xa, ya, xb, yb, xc, yc, [c])'] = [[### `tri(xa, ya, xb, yb, xc, yc, [c])`
- Draws an empty triangle.]],

['line(xa, ya, xb, yb, [c])'] = [[### `line(xa, ya, xb, yb, [c])`
- Draws a line.]],

['pset(x, y, [c])'] = [[### `pset(x, y, [c])`
- Sets the color of one pixel.]],

['str_px_width(str)'] = [[### `str_px_width(str)`
- Returns the width in pixels of the string `str` as it would be rendered.
- Font defaults to the current active font.]],

['print(str, x, y, [c])'] = [[### `print(str, x, y, [c])`
- Draws the string `str` on the screen at the coordinates {x; y}.]],

['printp(a, b, c, d)'] = [[### `printp(a, b, c, d)`
- Defines the print pattern for `pprint(...)`.
- `a, b, c, d` are to be defined as such:
```lua
  printp( 0x3330,
          0x3130,
          0x3230,
          0x3330 )
```
- The text will be drawn multiple times, with offsets according to the numbers' positions on the pattern, with the colors defined in `printp_color(...)`. 2 will be drawn on top of 3, and 1 will be drawn on top of 2.]],

['printp_color(c1, c2, c3)'] = [[### `printp_color(c1, c2, c3)`
- Sets the colors for `pprint(...)`.]],

['pprint(str, x, y, c1, c2, c3)'] = [[### `pprint(str, x, y, c1, c2, c3)`
- Draw text with the pattern defined by the last `printp(...)` call.]],

['cos(a)'] = [[### `cos(a)`
- Returns the cosine of `a` as a turn-based angle.]],

['sin(a)'] = [[### `sin(a)`
- Returns the sine of `a` as a turn-based angle.]],

['atan2(x, y)'] = [[### `atan2(x, y)`
- Converts {`x`; `y`} as an angle from 0 to 1. Returns that angle.]],

['lerp(a, b, i)'] = [[### `lerp(a, b, i)`
- Returns the linear interpolation from `a` to `b` with the parameter `i`.
- For the intended use, `i` should be between `0` and `1`. However it is not limited to those value.]],

['flr(a)'] = [[### `flr(a)`
- Returns the closest integer that is equal or below `a`.]],

['ceil(a)'] = [[### `ceil(a)`
- Returns the closest integer that is equal or above `a`.]],

['round(a)'] = [[### `round(a)`
- Returns the closest integer to `a`.]],

['sgn(a)'] = [[### `sgn(a)`
- Returns `1` if `a` is positive.
- Returns `-1` if `a` is negative.
- Returns `0` if `a` is zero.]],

['sqr(a)'] = [[### `sqr(a)`
- Returns `a * a`.]],

['cub(a)'] = [[### `cub(a)`
- Returns `a * a * a`.]],

['pow(a, b)'] = [[### `pow(a, b)`
- Returns the result of `a` to the power of `b`.
- `pow(a, 2)` is **much slower** than `sqr(a)`.]],

['sqrt(a)'] = [[### `sqrt(a)`
- Returns the square root of `a`.]],

['abs(a)'] = [[### `abs(a)`
- Returns the absolute (positive) value of `a`.]],

['min(a, b)'] = [[### `min(a, b)`
- Returns the lower value between `a` and `b`.]],

['max(a, b)'] = [[### `max(a, b)`
- Returns the higher value between `a` and `b`.]],

['mid(a, b, c)'] = [[### `mid(a, b, c)`
- Returns the middle value between `a`, `b` and `c`.
- `mid(1, 3, 2)` will return `2`.]],

['angle_diff(a1, a2)'] = [[### `angle_diff(a1, a2)`
- Returns the difference between the turn-based angle `a1` and the turn-based angle `a2`.]],

['dist(x1, y1, [x2, y2])'] = [[### `dist(x1, y1, [x2, y2])`
- If x2 and y2 are set, returns the distance between {x1; y1} and {x2; y2}.
- Otherwise, returns the distance between {0; 0} and {x1; y1}.]],

['sqrdist(x, y)'] = [[### `sqrdist(x, y)`
- Returns the squared distance between {0; 0} and {x1; y1}.
- Is faster than `dist(...)`.]],

['srand(seed)'] = [[### `srand(seed)`
- Sets the seed for the random number generation.]],

['raw_rnd()'] = [[### `raw_rnd()`
- Returns a random number.
- Always returns an integer.]],

['rnd(n)'] = [[### `rnd(n)`
- Returns a random decimal number between `0` *(included)* and `n` *(excluded)*.]],

['irnd(n)'] = [[### `irnd(n)`
- Returns a random integer number between `0` *(included)* and `n` *(excluded)*.]],

['pick(tab)'] = [[### `pick(tab)`
- Takes an ordered table *(with linear numeral keys)* as parameter.
- Returns a random element from the table.]],

['t()'] = [[### `t()`
- Returns the time in seconds since the program's start-up.]],

['time()'] = [[### `time()`
- Alias for `t()`.]],

['dt()'] = [[### `dt()`
- Returns the time between this frame and the previous one.]],

['delta_time()'] = [[### `delta_time()`
- Alias for `dt()`.]],

['freeze(sec)'] = [[### `freeze(sec)`
- Stops the program for `sec` seconds.
- Using this function will **not** affect `dt()`.]],

['sys_ltime()'] = [[### `sys_ltime()`
- Get the system time in the local time zone.
- Returns, in this order:
  - seconds (`0 - 59`)
  - minutes (`0 - 59`)
  - hour (`0 - 23`)
  - day (`1 - 31`)
  - month (`1 - 12`)
  - year (full year)
  - week day (`1 - 7`)]],

['sys_gtime()'] = [[### `sys_gtime()`
- Get the system time as UTC time.
- Returns, in this order:
  - seconds (`0 - 59`)
  - minutes (`0 - 59`)
  - hour (`0 - 23`)
  - day (`1 - 31`)
  - month (`1 - 12`)
  - year (full year)
  - week day (`1 - 7`)]],

['all(ar)'] = [[### `all(ar)`
- To use with `for` to iterate through the elements of the ordered table `ar`.
- e.g:
```lua
local tab = {1, 2, 3}
for n in all(tab) do
  print(n)
end
-- > 1   2   3
```]],

['del(ar, val)'] = [[### `del(ar, val)`
- Finds and removes the first occurence of `val` in the ordered table `ar`.
- If `ar` does not contain `val`, nothing happens.]],

['del_at(ar, n)'] = [[### `del_at(ar, n)`
- Removes the item at position `n` in the ordered table `ar`.]],

['add(ar, v)'] = [[### `add(ar, v)`
- Adds the item `v` to the end of the ordered table `ar`.]],

['sort(ar)'] = [[### `sort(ar)`
- Sorts the ordered table `ar`.]],

['merge_tables(dst, src)'] = [[### `merge_tables(dst, src)`
- Copies all the keys from the table `src` into the table `dst`.
- Returns `dst`.]],

['copy_table(tab, [deep])'] = [[### `copy_table(tab, [deep])`
- Returns a copy of the table `tab`.
- If `deep` is `true`, the copy will have copies of any tables found inside `tab` and so will those.
- /!\ Avoid setting `deep` to `true` when operating on tables linking to other tables in your structure, especially if you're working with double-linked tables, as that would create an infinite loop.]],
    }
  
    function doc_browser()
      if cat == "Introduction" then
        cat = ui.radioButtonGroup("Category", cat, categories, {hideLabel = true})
      else
        ui.box("doc_radiobuttons", {flexDirection = "row", justifyContent = "space-between"}, function()
          ui.box("doc_categories", {width = 0.35}, function()
            cat = ui.radioButtonGroup("Category", cat, categories, {hideLabel = true})
          end)
          
          ui.box("doc_functions", {width = 0.6}, function()
            local list = foo_names[cat]
            foo = ui.radioButtonGroup("Function", foo or "", list, {hideLabel = true})
          end)
        end)
      end
      
      if cat == "Introduction" then
        ui.markdown(doc.introduction)
      else
        ui.markdown(doc[foo] or "")
      end
      
    end
  end

  -- testing ui

  function testing_ui()
    if testing then
      if ui.button("[Stop]") then
        stop_testing()
      end
    else
      if ui.button("[Play]") then
        test_game()
      end
    end

    if runtime_error then
      ui.markdown("`Runtime error:`")
      ui.markdown("`"..runtime_error.."`")
    end
  end

end


do ---- Misc

  function point_in_rect(x, y, x0, y0, x1, y1)
    return (x >= x0 and x < x1 and y >= y0 and y < y1)
  end

  function love.keypressed(k)
    local p = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")

    if k == 's' and p then
      save_game()
    end
    
    if k == 'p' and p then
      if testing then
        stop_testing()
      else
        test_game()
      end
    end
  end

end


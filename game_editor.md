# Game Editor API Documentation


## Contents:
- [Introduction](#Introduction)
- [Framework functions](#Framework-functions)
- [Sugarcoat functions](#Sugarcoat-functions)
- [Standard functions](#Standard-functions)


## Introduction

The Collection Game Editor limits the base functions available to you for two reasons:

- Providing a simpler environment for you to make cool stuff with
- Making sure you don't break the environment

In consequence, most of the functions available to you come directly from Sugarcoat, while `love` and all its functions are banished. `castle` and its functions are also banished, as our game framework needs exclusivity over their features to function properly.

In addition to this, here are some quirks resulting from the design of the game framework and the use of Sugarcoat:

- The only assets you may use are the glyphs provided by the framework. You cannot use external assets. However you may use primitive drawing functions.
- You may only use the colors from the palette provided by the framework. When drawing glyphs or primitive shapes, you can use any color by passing its index in the palette.
- The game's resolution is fixed to 256x192 pixels.
- You may only use the inputs defined manually in the "Game Info" panel.



## Framework functions

### Subcontent:
- [`gameover`](#gameoverscore-stats)
- [`glyph`](#glyphn-x-y-width=height-angle-color_a-color_b-anchor_x--8-anchor_y--8)
- [`outlined_glyph`](#outlined_glyphn-x-y-width=height-angle-color_a-color_b-outline_color-anchor_x--8-anchor_y--8)
- [`screenshot`](#screenshot)
- [`screenshake`](#screenshakepower)
- [`btn`](#btninput)
- [`btnp`](#btnpinput)
- [`btnr`](#btnrinput)
- [`btnv`](#btnvinput)

&#8202;
    
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

## Standard functions

Those standard package and functions are also available to you:

- `table`
- `string`
- `bit`
- `network` *([actually a Castle package](https://www.playcastle.io/documentation/code-loading-reference))*

- `unpack`
- `select`
- `pairs`
- `ipairs`
- `type`
- `getmetatable`
- `setmetatable`
- `error`
- `tostring`
- `tonumber`

You will find documentation for any of those packages and functions with a simple online search along the lines of "lua [package/function]".

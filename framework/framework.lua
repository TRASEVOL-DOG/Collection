-- framework for Collection project
--
--

-- here's some values the framework gives out:
-- - _difficulty : 0 is super easy, 100 should be near-impossible (we'll scale it internally - game 25 would have a difficulty of 100)

-- here's what the player should define (as global)
-- - _title: name of the game
-- - _description: a one sentence description/instruction for the game
-- - _controls : table listing the controls you're using in this game
-- - _cursor_info : table with a 'glyph' key and 'color_a', 'color_b', 'outline', 'anchor_x' and 'anchor_y' and 'angle' keys. This table lets the user replace the cursor with a glyph. Keep that table as nil if you prefer to keep the default cursor.
-- - 
-- - _init() : callback called on loading the game
-- - _update() : callback called every frame to update the game
-- - _draw() : callback called every frame to draw the game
--

-- Chain general info
  -- Going from a game to another / Go To Game : "gtg"
  -- "global_score" and "battery" are to be passed into the parameters when gtg. if it's the first link in chain, the framework will go with default value (0 and 100 respectively)
  -- The game_registry is now at "https://raw.githubusercontent.com/TRASEVOL-DOG/Collection/master/game_registery" and should be moved on later, maybe on the leaderboard repo.
  -- game_previews contains the game previews for the game over screen, inited in chain_init()



-- Notes on control system:
-- directions map to arrow keys, WASD, and the controller left stick
-- A and B map to Z and X, enter and rshift, and the controller A and B buttons
-- cursor position is mouse poistion, and/or simulated cursor controlled with controller right stick
-- cursor clics are mouse lb and rb, and controller right bumper and trigger.



-- Todo:
----- forbid all sugar functions except some
---
----- load audio assets
---
----- shader?
---
----- pause/settings button + panel
---
----- game over screen
---
----- ui bar
---

if CASTLE_PREFETCH then
  CASTLE_PREFETCH({
    "sugarcoat/sugarcoat.lua",
    "framework/glyphs.png",
    "framework/controls.png",
    "framework/screen_dither.png",
    "framework/topbar.png",
    "framework/Awesome.ttf"
  })
end

require("sugarcoat/sugarcoat")
require("framework/game_list")
sugar.utility.using_package(sugar.S, true)
local S = sugar.S

local GAME_WIDTH, GAME_HEIGHT = 256, 192
local TOPBAR_HEIGHT = 16

-- forward declarations (local):
local load_palette, load_controls, load_assets
local update_controls, draw_cursor
local init_controls_screen, update_controls_screen, draw_controls_screen
local update_topbar, draw_topbar
local pause, update_pause, draw_pause

local in_controls, in_pause, in_pause_t, in_gameover
local ctrl_descriptions, ctrl_active
local light_table

local battery_level
local global_score

do -- love overloads (load, update, draw)

  function love.load()
    init_sugar("Remy & Eliott's Collection", GAME_WIDTH, GAME_HEIGHT + TOPBAR_HEIGHT, 3)
    
    log("Initializing Collection framework.", "o7")
    
    -- setting default game info
    _title = _title or "[please set a title!]"
    _description = _description or "[please set a description!]"
    _controls = _controls or {}
    
    local params = castle.game.getInitialParams()
    
    if params then 
      battery_level = params.battery_level
      global_score = params.global_score
    end
    battery_level = battery_level or 100
    global_score = global_score or 0
    
    -- loading resources
    load_assets()
    load_controls()
    
    -- futur games will be defined in init
    -- for now, only return copy on game_list
    -- this will surely change when games will need more info to be inited (spr info and preview etc)
      reset_game_list_copy()
    --
    
    init_shown_games_game_over()
    
    init_controls_screen()
    
    log("Done initializing Collection framework, launching game!", "o7")
    
    if _init then _init() end
  end
  
  function love.update()
    update_controls()
    update_pause()
    
    if in_controls then update_controls_screen() return end
    if in_gameover then update_gameover() return end
    if in_pause then return end
  
    if _update then _update() end
  end
  
  function love.draw()
    camera()
    
    if _draw then _draw() end
    
    use_font("main")
    
    if in_pause_t then draw_pause() end
    
    if in_controls then draw_controls_screen() end
    if in_gameover then draw_gameover() end
    
    draw_topbar()
    
    camera()
    
    draw_cursor()
  end

end

local g_o_games = {} -- game over games

do -- preloading games  

  -- games have : 
  -- link 
  -- name
  -- cursor 
  -- preview.png  

  function init_shown_games_game_over()
    local choosen_games = pick_different(2, get_game_list())
    for i, g in pairs(choosen_games) do
      add(g_o_games, { name = g.name, player_spr = g.player_spr, preview = load_png(nil, g.preview) } )    
    end
  end
  function get_game_over_game_list()
    return g_o_games  
  end
end


do -- gameover
  local end_score, end_info, end_rank
  local gameover_t = 0
  
  local ranks = { "F", "E", "D", "C", "B", "A", "SM" }
  
  -- score has to be between 0 and 100
  -- info (optional) is a table of strings to display on gameover
  function gameover(score, info)
    in_gameover = true
    gameover_t = 0
    
    end_score = mid(score, 0, 100)
    end_info = info
    
    if score == 100 then
      end_rank = "A++"
    else
      local n = score / 100 * count(ranks)
      
      end_rank = ranks[flr(n + 1)]
      
      if n % 1 < 0.25 then
        end_rank = end_rank.."-"
      elseif n % 1 > 0.75 then
        end_rank = end_rank.."+"
      end
    end
  end

  function update_gameover()
    gameover_t = min(gameover_t + dt(), 1)
    
    -- manage 'continue' button here
  end
  
  function draw_gameover()
    -- todo:
    --- draw "game over" (or "you win" on 100/100)
    --- draw score
    --- draw rank
    --- continue (to next game selection)
    
  end
  
end


do -- topbar
  
  function draw_topbar()
    S.camera()
    --rectfill(0, 0, GAME_WIDTH-1, TOPBAR_HEIGHT-1, 16)
    
    spritesheet("topbar")
    palt(0, false)
    spr(0, 0, 0, 16, 1)
    palt(0, true)
    
    print(_title, 2, 0, 19)
    print(_title, 2, -1, 29)
    
    draw_battery(216, 0)
    
    local mx, my = btnv("cur_x"), btnv("cur_y")
    if mx >= 256 - 15 and mx < 256 and my >= -16 and my < -1 then
      spr(btn("cur_lb") and 21 or 20, 240, 0)
    else
      spr(19, 240, 0)
    end
    
    --todo:
    -- highlight pause button on hover and on press
    
    spritesheet("glyphs")
  end
  
  local battery_ramps = { -- color ramps for the battery icon
    {5, 12, 22, 29},
    {12, 13, 14, 29},
    {10, 15, 25, 29},
    {9, 10, 15, 29},
    {19, 27, 29, 29} -- white ramp
  }
  local bubbles = {
    [0]={2,34,66,77,101},{23,46,63,89,111,122},{15,53,93,116},{29,72,85,105},{7,38,79},{19,49,65,97,123},{0,31,60,76,114},{13,42,92,117},{5,27,56,70,81,106},{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127}
  }
    
  function draw_battery(x, y)
    local v = mid(battery_level / 100, 0, 1)
    
    pal(29, 19)
    spr(16, x, y+1, 2, 1)
    pal(29, 29)
    
    local rn
    if     battery_level > 60 then rn = 4
    elseif battery_level > 50 then rn = 3
    elseif battery_level > 20 then rn = 2
    else                           rn = 1
    end
    local ramp = battery_ramps[rn]
    
    clip(x+2, y+2, 20, 9)
    S.camera(-x-2, -y-2)
    
    local w0 = v*20
    local w1 = 0.85 * w0 - 1
    local w2 = min(0.2 * w0, w1 - 2)
    
    local t = t()
    for y = 0, 8 do
      local dx = 2 * cos(0.25*t + y/12) * cos(0.6*t + y/18)
    
      line(w1+0.75*dx, y, w0+dx, y, ramp[3])
      line(w2+0.5*dx, y, w1+0.75*dx, y, ramp[2])
      line(0, y, w2+0.5*dx, y, ramp[1])
      
      for _,x in pairs(bubbles[y]) do
        local x = (x + t*6) % 128
        
        x = sqr(sqr(x/20))*20
        if x < w0+dx then
          local v = 2
          if x > w1+0.75*dx then v = 4
          elseif x > w2+0.5*dx then v = 3 end
          
          pset(x, y, ramp[v])
        end
      end
      
      pset(w0+dx, y, ramp[4])
      pset(w0+dx, y+1, 19)
    end
    
    S.camera()
    clip()
    
    spr(16, x, y, 2, 1)
    
    local str = flr(battery_level)..'%'
    
    if battery_level < 20 then
      if battery_level > 5 or t%1.5 > 0.5 then
        print(str, 215 - str_px_width(str), 0, 19)
        print(str, 215 - str_px_width(str), -1, 12)
      end
    else
      print(str, 215 - str_px_width(str), 0, 19)
      print(str, 215 - str_px_width(str), -1, 29)
    end
  end

  
  -- overloading sugar functions
  function camera(x, y)
    S.camera(x or 0, (y or 0) - TOPBAR_HEIGHT)
  end
  
  function screen_h()
    return GAME_HEIGHT
  end
  
  function screen_size()
    return GAME_WIDTH, GAME_HEIGHT
  end
end


do -- controls screen

  function init_controls_screen()
    in_controls = 99
  
  
  end
  
  local control_mode = 0
  local mode_x, mode_y, mode_hover = 128-32, 30, false
  function update_controls_screen()
    if in_controls == 99 then
      if btnp("start") then
        in_controls = 1
        --in_controls = false
      end
      
      local mx, my = btnv("cur_x"), btnv("cur_y")
      if mx >= mode_x and mx < mode_x+64 and my >= mode_y and my < mode_y+16 then
        mode_hover = true
        if btnp("cur_lb") then
          control_mode = (control_mode + 1) % 3
        end
      else
        mode_hover = false
      end
    elseif in_controls then
      in_controls = in_controls - dt()
      
      if in_controls <= 0 then
        in_controls = false
        make_cursor_visible(false)
      end
    end
  end
  
  
  function draw_controls_screen() -- /!\ messy code
    if in_controls == 99 then
      cls(0)
    else
      local h = (2 * in_controls) * 192
      
      for y = 0, 192, 32 do
        local r = min((h - y) / 4, 32)
        if r > 0 then
          for x = y%64 / 2, 256, 32 do
            circfill(x, y, r, 0)
          end
        end
      end
      
      local y = cos(0.3 - in_controls * 0.3) * 200 - 200
      camera(0, -y)
    end
    
    printp(0x0000, 0x0100, 0x0200, 0x0300)
    printp_color(29, 19, 3)
    
    local x,y = 0, 8
    local space1, space2 = 18, 28
    
    x = (screen_w() - str_px_width(_description)) / 2

    pprint(_description, x, y)
  
    y = y + space2
    
    local controls_icons = { up = 0, left = 1, down = 2, right = 3, A = 4, B = 5, cur_x = 6, cur_y = 6, cur_lb = 7, cur_rb = 8 }
    
    spritesheet("controls")
    
    
    spr(9 + 16*control_mode, mode_x, mode_y, 4, 1)
    if mode_hover then
      spr(btn("cur_lb") and 60 or 56, mode_x, mode_y, 4, 1)
    end
    
    y = y + space1
    
    local mwa, mwb = 0, 0
    for _, d in ipairs(ctrl_descriptions) do
      local str, w = ": "..d[2], 0
      for _, v in ipairs(d[1]) do
        w = w + 17
      end
      w = w - 7
  
      mwa = max(mwa, w)
      mwb = max(mwb, str_px_width(str))
    end
    
    local x = (screen_w() - mwa - mwb) / 2 + mwa
    
    for _, d in ipairs(ctrl_descriptions) do
      local str, w = " : "..d[2], 0
      for _, v in ipairs(d[1]) do
        w = w + 17
      end
      w = w - 7
      
      local x = x - w
      
      for _, v in ipairs(d[1]) do
        spr(controls_icons[v] + control_mode * 16, x, y)
        x = x + 17
      end
      
      pprint(str, x, y)
      
      y = y + space1
    end
    
    if t()%1 < 0.75 then
      local str
      if control_mode == 2 then
        str = "Press START to continue!"
      else
        str = "Press E / Enter to continue!"
      end
      
      x = (screen_w() - str_px_width(str)) / 2
      y = screen_h() - 16
      pprint(str, x, y)
    end
    
    spritesheet("glyphs")
    
    camera()
  end

end


do -- pause

  function pause()
    if in_pause then
      in_pause = false
  
      castle.uiupdate = false
    else
      in_pause = true
      in_pause_t = in_pause_t or 0
    
      castle.uiupdate = ui_panel
    end
  end
  
  function update_pause()
    if btnp("start") and in_controls ~= 99 and not in_gameover then
      pause()
    end
    
    local mx, my = btnv("cur_x"), btnv("cur_y")
    if mx >= 256 - 15 and mx < 256 and my >= -16 and my < -1 and btnr("cur_lb") then
      pause()
    end
  
    if in_pause then
      in_pause_t = min(in_pause_t + 2 * dt(), 1)
    elseif in_pause_t then
      in_pause_t = in_pause_t - 2 * dt()
      if in_pause_t < 0 then
        in_pause_t = nil
      end
    end
  end
  
  function draw_pause()
    spritesheet("screen_dither")
    pal(1, 0)
    palt(0, true)
    
    if in_pause_t < 1 then
      local h = 1.2 * in_pause_t * 192 * 2 - 32
      
      -- do the transition here
      for y = h%32 - 32, min(h, 192)-1, 32 do
        local v = mid(flr((h - y) / 32), 0, 3)
        
        spr(v * 32, 0, y, 16, 2)
      end
      
      local y = sqr(cos(0.3 - in_pause_t * 0.3)) * 192 - 192
      camera(0, -y)
    else
      -- do the complete screen obscuring here
      for y = 0, 192-1, 32 do
        spr(96, 0, y, 16, 2)
      end
    end
    
    pal(1, 1)
    spritesheet("glyphs")
    
    printp(0x3330, 0x3130, 0x3230, 0x3330)
    printp_color(29, 19, 0)
    
    local str = "Pause!"
    local x, y = (screen_w() - str_px_width(str))/2, screen_h()/2 - 8
    for i = 1, #str do
      local ch = str:sub(i,i)
      pprint(ch, x, y + 2.5*cos(-t() + i/6))
      x = x + str_px_width(ch)
    end
    
    camera()
  end
  
  function ui_panel()
    local ui = castle.ui
    ui.markdown("### ".._title)
    ui.markdown(_description)
  end

end


do -- palette & glyphs

  function load_palette()
    local palette = {  -- "Glassworks", by Trasevol_Dog B-)
      0x000000, 0x000020, 0x330818, 0x1a0f4d,
      0x990036, 0x660000, 0x992e00, 0x332708,
      0x001c12, 0x00591b, 0x118f45, 0x998a26,
      0xff2600, 0xff8c00, 0xffff33, 0x6de622,
      0x0fff9f, 0x00ace6, 0x2e00ff, 0x772e99,
      0xb319ff, 0xff4f75, 0xff9999, 0xffc8a3,
      0xfeffad, 0xb1ff96, 0x99fff5, 0xbcb6e3,
      0xebebeb, 0xffffff
    }
    
    use_palette(palette)
    
    log("Using the Glassworks palette.", "o7")
  end
  
  function glyph(n, x, y, width, height, angle, color_a, color_b)
    width = width or 16
    height = height or 16
    angle = angle or 0
  
    pal(1, color_a or 0)
    pal(2, color_b or 0)
    aspr(n, x, y, angle, 1, 1, 0.5, 0.5, width/16, height/16)
    pal(1, 1)
    pal(2, 2)
  end
  
  function outlined_glyph(n, x, y, width, height, angle, color_a, color_b, outline_color)
    width = width or 16
    height = height or 16
    angle = angle or 0
  
    pal(1, outline_color)
    pal(2, outline_color)
    aspr(n, x-1, y, angle, 1, 1, 0.5, 0.5, width/16, height/16)
    aspr(n, x+1, y, angle, 1, 1, 0.5, 0.5, width/16, height/16)
    aspr(n, x, y-1, angle, 1, 1, 0.5, 0.5, width/16, height/16)
    aspr(n, x, y+1, angle, 1, 1, 0.5, 0.5, width/16, height/16)
  
    pal(1, color_a or 0)
    pal(2, color_b or 0)
    aspr(n, x, y, angle, 1, 1, 0.5, 0.5, width/16, height/16)
    pal(1, 1)
    pal(2, 2)
  end

end


do -- controls system

  local cur_x, cur_y, m_x, m_y = 0, 0, 0, 0
  local s_btn, s_btnv = btn, btnv
  function update_controls()
    for k, d in pairs(ctrl_active) do
      d.pstate = d.state
      
      if k == "left" then
        d.value = s_btnv("left") - min(s_btnv("lx_axis"), 0)
        d.state = d.value > 0
      elseif k == "right" then
        d.value = s_btnv("right") + max(s_btnv("lx_axis"), 0)
        d.state = d.value > 0
      elseif k == "up" then
        d.value = s_btnv("up") - min(s_btnv("ly_axis"), 0)
        d.state = d.value > 0
      elseif k == "down" then
        d.value = s_btnv("down") + max(s_btnv("ly_axis"), 0)
        d.state = d.value > 0
      elseif k == "cur_x" then
        d.value = d.value + 3* s_btnv("rx_axis")
        d.state = s_btn("rx_axis")
        
        local n_x = s_btnv("cur_x")
        if n_x ~= m_x then
          m_x, d.value = n_x, n_x
          d.state = true
        end
      elseif k == "cur_y" then
        d.value = d.value + 3* s_btnv("ry_axis")
        d.state = s_btn("ry_axis")
        
        local n_y = s_btnv("cur_y")
        if n_y ~= m_y then
          m_y, d.value = n_y, n_y - TOPBAR_HEIGHT
          d.state = true
        end
      else
        d.value = s_btnv(k)
        d.state = s_btn(k)
      end
    end
  end
  
  function btn(k)
    local d = ctrl_active[k]
    return d and d.state
  end
  
  function btnp(k)
    local d = ctrl_active[k]
    return d and d.state and not d.pstate
  end
  
  function btnr(k)
    local d = ctrl_active[k]
    return d and d.pstate and not d.state
  end
  
  function btnv(k)
    local d = ctrl_active[k]
    return d and d.value or 0
  end
  
  function load_controls()
    local bindings = {
      left   = { input_id("keyboard_scancode", "left"),
                 input_id("keyboard_scancode", "a"),
                 input_id("controller_button", "dpleft") },
      right  = { input_id("keyboard_scancode", "right"),
                 input_id("keyboard_scancode", "d"),
                 input_id("controller_button", "dpright") },
      up     = { input_id("keyboard_scancode", "up"),
                 input_id("keyboard_scancode", "w"),
                 input_id("controller_button", "dpup") },
      down   = { input_id("keyboard_scancode", "down"),
                 input_id("keyboard_scancode", "s"),
                 input_id("controller_button", "dpdown") },
      
      lx_axis = { input_id("controller_axis", "leftx") },
      ly_axis = { input_id("controller_axis", "lefty") },
      
      A =      { input_id("keyboard_scancode", "z"),
                 input_id("keyboard_scancode", "rshift"),
                 input_id("controller_button", "a") },
      B =      { input_id("keyboard_scancode", "x"),
                 input_id("keyboard_scancode", "return"),
                 input_id("controller_button", "b") },
  
      cur_x  = { input_id("mouse_position", "x") },
      cur_y  = { input_id("mouse_position", "y") },
      
      cur_lb = { input_id("mouse_button", "lb"),
                 input_id("controller_button", "rightshoulder") },
      cur_rb = { input_id("mouse_button", "rb"),
                 input_id("controller_axis", "triggerright") },
  
      rx_axis = { input_id("controller_axis", "rightx") },
      ry_axis = { input_id("controller_axis", "righty") }
    }
    
    player_assign_ctrlr(0, 0)
    
    ctrl_descriptions, ctrl_active = {}, {}
    
    for k, desc in pairs(_controls) do
      if not bindings[k] then
        error("There are no bindings for control '"..k.."'. Please only use the controls made available by the framework.")
      end
    
      local b = true
      for _,v in pairs(ctrl_descriptions) do
        if v[2] == desc then
          b = false
          
          local bb = false -- code below avoids having both cur_x and cur_y in the description table, as they have the same icons.
          if k == "cur_x" or k == "cur_y" then
            for _,vb in pairs(v[1]) do
              bb = bb or vb == "cur_x" or vb == "cur_y"
            end
          end
          
          if not bb then
            add(v[1], k)
          end
        end
      end
      
      if b then
        add(ctrl_descriptions, { {k}, desc})
      end
    end
  
    for k, d in pairs(bindings) do
      if k ~= "lx_axis" and k ~= "ly_axis" and k ~= "rx_axis" and k ~= "ry_axis" then
        ctrl_active[k] = { state = false, pstate = false, value = 0}
      end
      
      register_btn(k, 0, d)
    end
  
    register_btn("start", 0, { input_id("keyboard_scancode", "return"),
                               input_id("keyboard_scancode", "e"),
                               input_id("controller_button", "start") })
                               
    ctrl_active["start"] = { state = false, pstate = false, value = 0}
    
    log("Finished registering all controls!", "o7")
  end

end


do -- misc

  function draw_cursor()
    if _cursor_info and _cursor_info.glyph then
      local mx, my = btnv("cur_x"), btnv("cur_y")
      
      if _cursor_info.outline then
        outlined_glyph(
          _cursor_info.glyph,
          mx + 8 - (_cursor_info.point_x or 0),
          my + 8 - (_cursor_info.point_y or 0),
          16, 16,
          _cursor_info.angle or 0,
          _cursor_info.color_a or 29,
          _cursor_info.color_b or 27,
          _cursor_info.outline
        )
      else
        glyph(
          _cursor_info.glyph,
          mx + 8 - (_cursor_info.point_x or 0),
          my + 8 - (_cursor_info.point_y or 0),
          16, 16,
          _cursor_info.angle or 0,
          _cursor_info.color_a or 29,
          _cursor_info.color_b or 27
        )
      end
      return
    end
  
    palt(0, false)
    palt(16, true)
    spritesheet("controls")
    
    local mx, my = btnv("cur_x"), btnv("cur_y")
    if btn("cur_lb") then
      spr(51, mx, my)
    else
      spr(50, mx, my)
    end
    spr(btn("cur_lb") and 51 or 50, btnv("cur_x"), btnv("cur_y"))
    
    spritesheet("glyphs")
    palt(0, true)
    palt(16, false)
  end

  function count(tab)
    if not tab then return end
    local nb = 0
    for i, j in pairs(tab) do nb = nb + 1 end
    return nb  
  end
  
  function pick_different( number, tab )
    choosen = {}    
    for i = 1, number do
      local picked = pick(tab)
      
      while check_in(picked, choosen) do 
        picked = pick(tab)
      end
      choosen[i] = picked
    end    
    return choosen
  end
  
  function check_in(value, tab)
    for index, val in pairs(tab) do
      if val == value then return true end
    end
    return false
  end
  
  function get_battery_level()
    return battery_level
  end
  
  function get_global_score()
    return global_score
  end
  
  function load_assets()
    load_palette()
  
    load_font("framework/Awesome.ttf", 16, "main", true)
    
    load_png("glyphs",        "framework/glyphs.png", { 0x000000, 0xffffff, 0x888888}, true)
    load_png("screen_dither", "framework/screen_dither.png", { 0x000000, 0xffffff })
    load_png("controls",      "framework/controls.png")
    load_png("topbar",        "framework/topbar.png")
    
    spritesheet_grid(16, 16)
    palt(0, true)
    
    log("All framework assets loaded!", "o7")
  end  

end

-- framework for Collection project
--
--

-- here's what the user should define (as global)
-- - _title: name of the game
-- - _description  : a one sentence description/instruction for the game
-- - _controls     : table listing the controls you're using in this game
-- - _cursor_info  : table with a 'glyph' key and 'color_a', 'color_b', 'outline', 'point_x' and 'point_y' and 'angle' keys. This table lets the user replace the cursor with a glyph. Keep that table as nil if you prefer to keep the default cursor.
-- - _player_glyph : glyph index representing the player in the game
-- - 
-- - _init(difficulty) : callback called on loading the game. difficulty is passed as argument; 0 is super easy, 100 should be near-impossible (we'll scale it internally - game 25 would have a difficulty of 100)
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


if CASTLE_PREFETCH then
  CASTLE_PREFETCH({
    "sugarcoat/sugarcoat.lua",
    "framework/glyphs.png",
    "framework/controls.png",
    "framework/screen_dither.png",
    "framework/topbar.png",
    "framework/AwesomePro.ttf"
  })
end

require("sugarcoat/sugarcoat")
require("framework/game_list")
local _debug = debug
sugar.utility.using_package(sugar.S, true)

local GAME_WIDTH, GAME_HEIGHT = 256, 192
local TOPBAR_HEIGHT = 16

-- forward declarations (local):
local load_palette, load_controls, load_assets, load_settings
local update_controls, draw_cursor
local init_controls_screen, update_controls_screen, draw_controls_screen
local update_topbar, draw_topbar, add_battery
local pause, update_pause, draw_pause, ui_panel
local update_gameover, draw_gameover
local transition_a, transition_b, update_screenshake
local init_bg_glyphs, update_bg_glyphs, draw_bg_glyphs
local set_user_env, safe_call, reset_draw_environment

local in_controls, in_pause, in_pause_t, in_gameover
local ctrl_descriptions, ctrl_active
local light_table
local shake_power, shake_x, shake_y
local user_env
local env_copy

local battery_level
local global_score
local global_game_count
local difficulty
local BATTERY_COST = 10

do -- love overloads (load, update, draw)

  function love.load(from_editor)
    from_editor = (from_editor == "yes")
  
    if not from_editor then
      init_sugar("Remy & Eliott's Collection", GAME_WIDTH, GAME_HEIGHT + TOPBAR_HEIGHT, 3)
      set_frame_waiting(60)
    end
    
    log("Initializing Collection framework.", "o7")
    
    -- setting default game info
    _title        = _title or "[please set a title!]"
    _description  = _description or "[please set a description!]"
    _controls     = _controls or {}
    _player_glyph = _player_glyph or 0
    
    local params = castle.game.getInitialParams()
    
    if params then 
      battery_level = params.battery_level
      global_score = params.global_score
      global_game_count = params.global_game_count + 1
      difficulty = params.global_score 
      
      add_battery(-BATTERY_COST)
    else
      battery_level = 100
      global_score = 0
      global_game_count = 1
      difficulty = 10
    end
    
    difficulty = (global_game_count - 1) * 10
    
    -- screen shake initialization
    shake_x, shake_y = 0, 0
    
    -- loading resources
    if not from_editor then
      load_assets()
    end
    
    load_controls()
    load_settings()
    
    -- futur games will be defined in init
    -- for now, only return copy on game_list
    -- this will surely change when games will need more info to be inited (spr info and preview etc)
      reset_game_list_copy()
    --
    
    init_shown_games_game_over()
    
    init_controls_screen()
    
    log("Done initializing Collection framework, launching game!", "o7")
    
    if not from_editor then
      set_user_env()
    end
    
    safe_call(_init, difficulty)
  end
  
  function love.update()
    update_screenshake()
    update_controls()
    update_topbar()
    update_pause()
    
    if in_controls then update_controls_screen() return end
    if in_gameover then update_gameover() return end
    if in_pause then return end
  
    safe_call(_update)
  end
  
  function love.draw()
    camera()
    
    safe_call(_draw)
    reset_draw_environment()
    
    use_font("main")
    
    if in_pause_t then draw_pause() end
    
    if in_controls then draw_controls_screen() end
    if in_gameover then draw_gameover() end
    
    draw_topbar()
    
    camera()
    
    draw_cursor()
  end

end


do -- preloading games  
  
  local g_o_games -- game over games { {name, player_spr, preview}, .. }
  
  function init_shown_games_game_over()
    g_o_games = {}
    local choosen_games = pick_different(4, get_game_list())
    for i, g in pairs(choosen_games) do
      local data = {
        name = g.name,
        player_spr = g.player_spr,
        code_name = g.code_name
      }
      
      network.async(function()
        data.preview = load_png(nil, "https://raw.githubusercontent.com/TRASEVOL-DOG/Collection/master/"..g.code_name.."_preview.png")
      end)
      
      add(g_o_games, data)
    end
    
    log("Initialized info for next games.", "o7")
  end
  
  function get_game_over_game_list()
    return g_o_games
  end
  
  function next_game(code_name)
    log("Launching next game!", "o/")
  
    load_game(code_name, true, {
      battery_level     = battery_level or 100,
      global_score      = global_score  or 0,
      global_game_count = global_game_count or 0
    })
  end
  
end


do -- gameover
  local end_score, end_info, end_rank, end_battery
  local gameover_t, ogameover_t = 0
  local in_select, select_t, update_select, draw_select
  
  local ranks = { "F", "E", "D", "C", "B", "A" }
  
  -- score has to be between 0 and 100
  -- info (optional) is a table of up-to-5 strings to display on gameover
  function gameover(score, info)
    screenshake(16)
    init_bg_glyphs(2)  
  
    in_gameover = true
    gameover_t = 0
    
    score = mid(score, 0, 100)
    end_score = score
    
    if info then
      end_info = {}
      
      for i,str in ipairs(info) do
        if i > 5 then break end
        end_info[i] = str
      end
    end
    
    log("Game Over! Score is "..end_score.."/100.", "o7")
    
    if score > 50 then
      if score == 100 then
        end_battery = 15
      else
        end_battery = ceil((score-50) / 50 * 10)
      end
    end
    
    if score == 100 then
      end_rank = "A++"
    else
      local n = score / 100 * #ranks
      
      end_rank = ranks[flr(n + 1)]
      
      if n % 1 < 0.25 then
        end_rank = end_rank.."-"
      elseif n % 1 > 0.75 then
        end_rank = end_rank.."+"
      end
    end
  end

  function update_gameover()
    if in_select then
      update_select()
      return
    end
  
    update_bg_glyphs() 
    
    ogameover_t = gameover_t
    gameover_t = gameover_t + dt()
    
    if btnp("start") then
      gameover_t = 999
    end
    
    local wait_t
    
    if end_info then
      for i,_ in ipairs(end_info) do
        local nt = 1 + (i - 1) * 0.4
        if nt < gameover_t and nt > ogameover_t then
          screenshake(4)
        end
      end
      
      local nt = 1 + #end_info * 0.4
      if nt < gameover_t and nt > ogameover_t then
        screenshake(8)
      end
      
      wait_t = 1 + #end_info * 0.4
    else
      if gameover_t >= 1 and ogameover_t < 1 then
        screenshake(8)
      end
      
      wait_t = 1
    end
    
    wait_t = wait_t + 1.1
    if gameover_t >= wait_t and ogameover_t < wait_t then
      global_score = global_score + end_score
    end
    
    if end_battery then
      wait_t = wait_t + 1.5
      if gameover_t >= wait_t and ogameover_t < wait_t then
        add_battery(end_battery)
      end
    end
    
    wait_t = wait_t + 1
    if ogameover_t > wait_t then
      if btnp("start") then
        -- move on to next-game selection
      
        in_select = true
        select_t = 0
      end
    end
  end
  
  local rank_ramps = {
    { 1, 2,  5,  4,  12 },
    { 1, 3,  19, 20, 22 },
    { 2, 5,  6,  13, 14 },
    { 1, 3,  18, 17, 26 },
    { 8, 9,  10, 15, 25 },
    { 1, 8,  9,  10, 15 },
    { 1, 3,  19, 27, 29 }
  }
  
  function draw_gameover()
    if in_select then
      cls()
      -- draw_bg_glyphs()
      
      if select_t < 1.5 then
        local y = -cos(0.3 - max(select_t-0.5, 0) * 0.3) * 200 + 200
        camera(0, -y)
        
        draw_select()
        
        local y = cos(0.3 - max(1-select_t, 0) * 0.3) * 200 - 200
        camera(0, -y)
      else
        draw_select()
        return
      end
    else
      transition_a(gameover_t)
    end
    
    draw_bg_glyphs()
      
    printp(0x0100, 0x0200, 0x0300, 0x0)

    local space1, space2 = 16, 30
    
    local timepoint = 1
    if gameover_t < timepoint then return end
    
    local y = 0
    if end_info then
      y = 4
      
      printp_color(17, 18, 3)
      for i,str in ipairs(end_info) do
        local x = (screen_w() - str_px_width(str)) / 2
        pprint(str, x, y)
        
        y = y + space1
        
        timepoint = timepoint + 0.4
        if gameover_t < timepoint then return end
      end

      y = y - space1-- + space2
    end
    
    y = lerp(y, screen_h() - 16, 0.5) - 0.9 * space2
    
    local str
    if end_score == 100 then
      str = "YOU WIN!"
      printp_color(14, 13, 6)
    else
      str = "GAME OVER"
      printp_color(12, 4, 5)
    end
    
    local x = (screen_w() - str_px_width(str)) / 2
    
    for i = 1, #str do
      local ch = str:sub(i,i)
      pprint(ch, x, y + 3*cos(i/9 - 2*t()))
      
      x = x + str_px_width(ch)
    end
    
    y = y + 0.75 * space2
    
    timepoint = timepoint + 0.1
    if gameover_t < timepoint then return end
    
    local v = cos(min(gameover_t - timepoint, 1)*0.25 - 0.25)
    local ramp = { 0, 1, 3, 19, 27 }
    if v < 1 then
      local n = flr(v * #ramp + 1)
      printp_color(ramp[n], ramp[max(n-1, 1)], ramp[max(n-2, 1)])
    else
      printp_color(27, 19, 3)
    end
    
    local str = "Score: "..flr(v * end_score).."/100"
    local x = screen_w()/4 - str_px_width(str)/2
    pprint(str, x, y + v * 8)
    
    
    timepoint = timepoint + 0.5
    if gameover_t < timepoint then return end
    
    local v = cos(min(gameover_t - timepoint, 1)*0.25 - 0.25)
    local ramp
    if end_score == 100 then
      ramp = rank_ramps[7]
    else
      ramp = rank_ramps[flr(end_score/100 * 6) + 1]
    end
    
    if v < 1 then
      local n = flr(v * #ramp + 1)
      printp_color(ramp[n], ramp[max(n-1, 1)], ramp[max(n-2, 1)])
    else
      printp_color(ramp[5], ramp[4], ramp[3])
    end
    
    local str = "Rank: "..end_rank
    local x = 3*screen_w()/4 - str_px_width(str)/2
    pprint(str, x, y + v * 8)
    
    
    if end_battery then
      y = y + 1.5 * space1
      
      timepoint = timepoint + 1
      if gameover_t < timepoint then return end
      
      local v = cos(min(gameover_t - timepoint, 1)*0.25 - 0.25)
      local ramp = rank_ramps[3]
      
      local ca, cb, cc
      if v < 1 then
        local n = flr(v * #ramp + 1)
        ca, cb, cc = ramp[n], ramp[max(n-1, 1)], ramp[max(n-2, 1)]
        printp_color(ca, cb, cc)
      else
        ca, cb, cc = ramp[5], ramp[4], ramp[3]
        printp_color(ca, cb, cc)
      end
      
      local str = "+"..end_battery.."%"
      local w = str_px_width(str)
      local x = screen_w()/2 - (w + 20)/2
      
      pprint(str, x, y + v * 8)
      
      glyph(0x70, x+w+4+8, y+8 + v * 8, 16, 16, 0, cc, cc)
      glyph(0x70, x+w+4+8, y+8 + v * 8 - 1, 16, 16, 0, ca, cb)
    end
    
    y = y + space2
    
    timepoint = timepoint + 1
    if gameover_t < timepoint then return end
    
    if gameover_t%1 < 0.75 then
      local str = "Press E / ENTER / START to continue!"
      
      printp_color(29, 19, 3)
      x = (screen_w() - str_px_width(str)) / 2
      y = screen_h() - 16
      pprint(str, x, y)
    end
  end
  
  
  -- game selection screen
  
  local game_w, game_h = 86, 64
  local space_w, space_h = 48, 20
  
  local wave_print, for_games_do
  rainbow_ramps = {
    { 14, 13, 6 },
    { 15, 10, 9 },
    { 17, 18, 3 },
    { 20, 19, 3 },
    { 12, 4,  2 },
    { 13, 6,  2 }
  }
  
  function update_select()
  
    update_bg_glyphs() 
    
    select_t = select_t + dt()
    
    local mx, my, mb = btnv("cur_x"), btnv("cur_y")
    for_games_do(function(game, x, y)
      if mx > x and mx < x+game_w and my > y and my < y+game_h and btnr("cur_lb") then
        next_game(game.code_name)
        _player_glyph = game.player_spr
      end
    end)
  end
  
  function draw_select()
  
    draw_bg_glyphs()
    printp(0x0100, 0x0200, 0x0300, 0x0)
  
    wave_pprint("Select Next Game!", screen_w()/2, 5, true)
    
    local p_glyph = _player_glyph
    local n_glyph
    
    local mx, my, mb = btnv("cur_x"), btnv("cur_y"), btn("cur_lb")
    for_games_do(function(game, x, y)
      local sp, dy
      if mx > x and mx < x+game_w and my > y and my < y+game_h then
        n_glyph = game.player_spr
        
        if mb then
          sp, dy = 12, 2
          p_glyph = n_glyph
        else
          sp, dy = 6, 1
        end
      else
        sp, dy = 0, 0 
      end
      
      palt(0, false)
      if game.preview then
        spr_sheet(game.preview, x, y + dy, 86, 64)
      end
      
      spritesheet("select")
      
      palt(15, true)
      spr(sp, x-5, y-8, 6, 5)
      palt(15, false)
      
      spritesheet("glyphs")
      palt(0, true)
      
      if dy == 0 then
        printp_color(29, 19, 3)
        
        pprint(game.name, x + 43 - str_px_width(game.name)/2, y-15)
      else
        wave_pprint(game.name, x + 43, y-15, true)
      end
    end)
    
    local x,y = screen_w()/2, screen_h()/2 - 16
    local t = t()
    
    glyph(p_glyph or 0, x, y, 16, 16, 0.1*cos(t), 29, 27)
    
    if n_glyph then
      for i = 1,6 do
        local a = i/6 + 0.25*t
        local x = x + 20*cos(a)
        local y = y + 20*sin(a)
        
        local ramp = rainbow_ramps[flr(i - t*8) % 6 + 1]
        
        glyph(n_glyph or 0, x, y, 16, 16, a - 0.5*t, ramp[1], ramp[2])
      end
    end
  end
  

  function for_games_do(foo) -- foo takes in 'game', 'x' and 'y'
    local games = get_game_over_game_list()
    
    local nh = ceil(#games/2)
    local nw = min(#games, 2)
    
    local wspace = space_w + 16
    
    local ox = screen_w()/2 - nw/2 * game_w - (nw - 1)/2 * wspace
    local x, y = ox, screen_h()/2 + 16 - nh/2 * game_h - (nh - 1)/2 * space_h
    
    for i, game in ipairs(games) do
      foo(game, x, y)
      
      if (i-1) % nw == nw-1 then
        wspace = wspace - 32
        ox = ox + (nw-1)/2 * 32
        x = ox
        y = y + game_h + space_h
      else
        x = x + game_w + wspace
      end
    end
  end
  
  function wave_pprint(str, x, y, rainbow)
    local x = x - str_px_width(str)/2
    local t = t()
    
    if rainbow then
      for i = 1, #str do
        printp_color(unpack(rainbow_ramps[flr(i-t*8) % #rainbow_ramps +1]))
      
        local ch = str:sub(i,i)
        pprint(ch, x, y + 3 * cos(-t + i/8))
        
        x = x + str_px_width(ch)
      end
    else
      for i = 1, #str do
        local ch = str:sub(i,i)
        pprint(ch, x, y + 3 * cos(-t + i/8))
        
        x = x + str_px_width(ch)
      end
    end
  end
end


do -- topbar
  local battery_t = 0

  function add_battery(n)
    battery_level = mid(battery_level + n, 0, 100)
    battery_t = 2
  end
  
  function update_topbar()
    local mx, my = btnv("cur_x"), btnv("cur_y")
    if mx >= 256 - 15 and mx < 256 and my >= -16 and my < -1 and btnr("cur_lb") then
      pause()
    end
    
    if battery_t > 0 then
      battery_t = battery_t - dt()
    end
  end
  
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
    if battery_t > 1.5 or (battery_t > 0 and battery_t % 0.2 < 0.1) then rn = 5 
    elseif battery_level > 60 then rn = 4
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
    
    local str = flr(battery_level)..""
    
    if battery_level < 20 then
      if battery_level > 5 or t%1.5 > 0.5 then
        print(str, 207 - str_px_width(str), 0, 19)
        print(str, 207 - str_px_width(str), -1, 12)
      end
    else
      print(str, 207 - str_px_width(str), 0, 19)
      print(str, 207 - str_px_width(str), -1, 29)
    end
  end

  
  -- overloading sugar functions
  function camera(x, y)
    S.camera(x or 0 + shake_power/100 * shake_x, (y or 0) - TOPBAR_HEIGHT + shake_power/100 * shake_y)
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
    
    init_bg_glyphs()
  end
  
  local control_mode = 0
  local mode_x, mode_y, mode_hover = 128-32, 30, false
  function update_controls_screen()
    update_bg_glyphs()
    if in_controls == 99 then
      if btnp("start") then
        in_controls = 1
        log("Leaving controls screen.", "o7")
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
      end
    end
  end
  
  function draw_controls_screen() -- /!\ messy code
    transition_a(in_controls)
    
    draw_bg_glyphs()
    
    printp(0x0000, 0x0100, 0x0200, 0x0300)
    printp_color(29, 19, 3)
    
    local x,y = 0, 8
    local space1, space2 = 18, 28
    
    local w = str_px_width(_description)
    
    if w >= 256 then
      local i = flr(#_description/2)
      while i > 1 and _description:sub(i,i) ~= " " do
        i = i-1
      end
      
      local str = _description:sub(1, i-1)
      pprint(str, (screen_w() - str_px_width(str)) / 2, y)
      
      y = y + space1
      local str = _description:sub(i+1, #_description)
      pprint(str, (screen_w() - str_px_width(str)) / 2, y)
      
      mode_y = 30 + space1
    else
      x = (screen_w() - w) / 2
      pprint(_description, x, y)
    end
    
    y = y + space2
    
    local controls_icons = { up = 0, left = 1, down = 2, right = 3, A = 4, B = 5, cur_x = 6, cur_y = 6, cur_lb = 7, cur_rb = 8 }
    
    spritesheet("controls")
    
    
    spr(9 + 16*control_mode, mode_x, mode_y, 4, 1)
    if mode_hover then
      spr(btn("cur_lb") and 60 or 56, mode_x, mode_y, 4, 1)
    end
    
    --y = y + space1
    
    local mwa, mwb, n = 0, 0, 0
    for _, d in ipairs(ctrl_descriptions) do
      local str, w = ": "..d[2], 0
      for _, v in ipairs(d[1]) do
        w = w + 17
      end
      w = w - 16
  
      mwa = max(mwa, w)
      mwb = max(mwb, str_px_width(str))
      
      n = n + 1
    end
    
    local x = (screen_w() - mwa - mwb) / 2 + mwa
    
    y = lerp(y, screen_h() - 16, 0.5) - (n) * space1 * 0.5
    
    for _, d in ipairs(ctrl_descriptions) do
      local str, w = ": "..d[2], 0
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
        str = "Press E / ENTER to continue!"
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
      log("Unpause!", "o7")
  
      castle.uiupdate = false
    else
      in_pause = true
      in_pause_t = in_pause_t or 0
      log("Pause!", "o7")
    
      castle.uiupdate = ui_panel
    end
  end
  
  function update_pause()
    if btnp("start") and in_controls ~= 99 and not in_gameover then
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
    transition_b(in_pause_t)
    
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
  
  
  
  local ui = castle.ui
  local function slider_react(label, value, min, max, foo)
    local nv = ui.slider(label, value, min, max)
  
    if nv ~= value then
      foo(nv)
    end
  
    return nv
  end
  
  function ui_panel()
    ui.markdown("## ".._title)
    ui.markdown(_description)

    ui.markdown([[&#160;
### Settings]])
  
    slider_react("Screenshake", shake_power, 0, 200, function(nv)
      shake_power = nv
      screenshake(2)
    end)
  
    ui.markdown("*To-do: implement vvv*")
  
    slider_react("Sfx Volume", sfx_volume()*100, 0, 100, function(nv)
      sfx_volume(nv * 100)
    end)
  
    slider_react("Music Volume", music_volume()*100, 0, 100, function(nv)
      music_volume(nv * 100)
    end)
  
    ui.toggle("Shader OFF", "Shader ON", false, { onToggle = function()
      -- do the shader things, i dunno
    end})
  
    ui.markdown(
[[&#160;
### Info
Collection (working title) is a project by [Eliott](https://twitter.com/Eliott_MacR) and [Trasevol_Dog](https://twitter.com/TRASEVOL_DOG)!
]]
    )

  end

end


do -- background_glyphs  

  bg_g_color_pairs = {
    { 8, 1 },
    { 3, 1 },
    { 2, 1 },
    { 5, 2 },
    { 18, 3 },
    { 19, 5 },
    { 6, 5 },
    { 9, 8 },
    { 4, 5 },
  }
  
  function init_bg_glyphs(timer)
    bg_glyphs = {}
    bg_timer = timer or 0
    for i = 1, #bg_g_color_pairs do add( bg_glyphs, {}) end
  end
  
  local function new_bg_g()
    local g = {spr = irnd(16),x = irnd(GAME_WIDTH), y = GAME_HEIGHT + 16, a = rnd(1), r_speed = (irnd(2) - 0.5) * (0.1 + rnd(2.4)) }
    g.d = 1 + irnd(#bg_g_color_pairs)
    g.size = 8 + g.d
    g.vspeed =  3 + ((3 + rnd(5)) * (g.d/ #bg_g_color_pairs))
    add( bg_glyphs[g.d], g)
  end
  
  function update_bg_glyphs()
    bg_timer = bg_timer - dt()
    if bg_timer < 0 then
      new_bg_g()
      bg_timer = .65 + rnd(1.5)
    end
    for i = 1, #bg_glyphs do
      for j, g in pairs(bg_glyphs[i]) do
      g.y = g.y - g.vspeed * dt()
      g.a = g.a + g.r_speed * dt() / 10
      if g.y < -16 then del_at(bg_glyphs[i], j) end
      end
    end
  end
  
  function draw_bg_glyphs()
    for i = 1, #bg_glyphs do
      for j, g in pairs(bg_glyphs[i]) do
        glyph(g.spr,  g.x, g.y, g.size, g.size, g.a, bg_g_color_pairs[g.d][1], bg_g_color_pairs[g.d][2], 0)
      end    
    end    
  end

end


do -- palette & glyphs

  function load_palette()
    local palette = {  -- "Glassworks", by Trasevol_Dog B-)
      0x000000, 0x000029, 0x330818, 0x1a0f4d,
      0x990036, 0x660000, 0x992e00, 0x332708,
      0x001c12, 0x00591b, 0x118f45, 0x998a26,
      0xff2600, 0xff8c00, 0xffff33, 0x6de622,
      0x0fff9f, 0x00ace6, 0x2e00ff, 0x772e99,
      0xb319ff, 0xff4f75, 0xff9999, 0xffc8a3,
      0xfeffad, 0xb1ff96, 0x99fff5, 0x968fbf,
      0xd0ced9, 0xffffff
    }
    
    use_palette(palette)
    
    log("Using the Glassworks palette.", "o7")
  end
  
  function glyph(n, x, y, width, height, angle, color_a, color_b, anchor_x, anchor_y) -- anchor_x and anchor_y are optional and are pixel coordinates
    width = width or 16
    height = height or 16
    angle = angle or 0
    anchor_x = anchor_x or 8
    anchor_y = anchor_y or 8
  
    pal(1, color_a or 0)
    pal(2, color_b or 0)
    aspr(n, x, y, angle, 1, 1, anchor_x/16, anchor_y/16, width/16, height/16)
    pal(1, 1)
    pal(2, 2)
  end
  
  function outlined_glyph(n, x, y, width, height, angle, color_a, color_b, outline_color, anchor_x, anchor_y)
    width = width or 16
    height = height or 16
    angle = angle or 0
    
    local ax = (anchor_x or 8)/16
    local ay = (anchor_y or 8)/16

    pal(1, outline_color)
    pal(2, outline_color)
    aspr(n, x-1, y, angle, 1, 1, ax, ay, width/16, height/16)
    aspr(n, x+1, y, angle, 1, 1, ax, ay, width/16, height/16)
    aspr(n, x, y-1, angle, 1, 1, ax, ay, width/16, height/16)
    aspr(n, x, y+1, angle, 1, 1, ax, ay, width/16, height/16)
  
    pal(1, color_a or 0)
    pal(2, color_b or 0)
    aspr(n, x, y, angle, 1, 1, ax, ay, width/16, height/16)
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


do -- user environment

  function set_user_env()
    for n,v in pairs(getfenv(1)) do
      if env_copy[n] == nil then
        if type(v) == "function" then
          setfenv(v, user_env)
        end
        
        user_env[n] = v
      end
    end
  
    if _init then
      setfenv(_init, user_env)
    end
    
    if _update then
      setfenv(_update, user_env)
    end
    
    if _draw then
      setfenv(_draw, user_env)
    end
  end

  function safe_call(foo, ...)
    if not foo then return end
  
    local r,trace = xpcall(foo, _debug.traceback, ...)
    
    if not r then
      sugar.debug.r_log(trace)
    end
  end

  function reset_draw_environment()
    camera()
    clip()
    pal()
    palt()
  end
  
end


do -- misc

  function screenshot()
    local surf = new_surface(256, 192, "screenshot")
    
    target(surf)
    palt(0, false)
    spr_sheet("__screen__", 0, -16)
    
    surfshot(surf, 1, _title..".png")
    
    target()
    delete_surface(surf)
    palt(0, true)
  end

  function screenshake(power)
    local a = rnd(1)
    
    shake_x = shake_x + power * cos(a)
    shake_y = shake_y + power * sin(a)
  end
  
  local shake_t = 0
  function update_screenshake()
    shake_t = shake_t - dt()
    if shake_t < 0 then
      if abs(shake_x) + abs(shake_y) < 0.5 then
        shake_x, shake_y = 0, 0
      else
        shake_x = shake_x * (-0.5 - rnd(0.2))
        shake_y = shake_y * (-0.5 - rnd(0.2))
      end
      
      shake_t = 0.03
    end
  end
  
  function transition_a(t)
    if t < 1 then
      local h = 2 * t * 192
      
      for y = 0, 192, 32 do
        local r = min((h - y) / 4, 32)
        if r > 0 then
          for x = y%64 / 2, 256, 32 do
            circfill(x, y, r, 0)
          end
        end
      end
      
      local y = cos(0.3 - t * 0.3) * 200 - 200
      camera(0, -y)
    else
      cls(0)
    end
  end
  
  function transition_b(t)
    spritesheet("screen_dither")
    pal(1, 0)
    palt(0, true)
    
    if t < 1 then
      local h = 1.2 * t * 192 * 2 - 32
      
      -- do the transition here
      for y = h%32 - 32, min(h, 192)-1, 32 do
        local v = mid(flr((h - y) / 32), 0, 3)
        
        spr(v * 32, 0, y, 16, 2)
      end
      
      local y = sqr(cos(0.3 - t * 0.3)) * 192 - 192
      camera(0, -y)
    else
      for y = 0, 192-1, 32 do
        spr(96, 0, y, 16, 2)
      end
    end
    
    pal(1, 1)
    spritesheet("glyphs")
  end
  
  function load_settings()
    -- to-do: load user settings from storage
    
    shake_power = 100
  end

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
  
  function load_assets()
    load_palette()
  
    load_font("framework/AwesomePro.ttf", 16, "main", true)
    
    load_png("glyphs",        "framework/glyphs.png", { 0x000000, 0xffffff, 0x888888}, true)
    load_png("screen_dither", "framework/screen_dither.png", { 0x000000, 0xffffff })
    load_png("controls",      "framework/controls.png")
    load_png("topbar",        "framework/topbar.png")
    load_png("select",        "framework/select.png")
    
    spritesheet_grid(16, 16)
    palt(0, true)
    
    log("All framework assets loaded!", "o7")
  end  

end


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
  castle          = castle,
  
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
  pget            = pget,
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
  screenshake     = screenshake
}

env_copy = copy_table(getfenv(1))
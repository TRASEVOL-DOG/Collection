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
    "[+] new function",
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
      
      function_list = { "[+] new function" }
      for _,f in ipairs(functions) do
        add(function_list, f.def)
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
  local chosen = ui.dropdown("Function", cur_function.def, function_list)
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
        local nv = ui.textInput( "argument"..i, args[i] or "", {hideLabel = true})
        if nv == "" and args[i] then
          del(args, i)
          update_def(cur_function)
          i = i - 1
        elseif nv ~= "" and nv ~= args[i] then
          args[i] = nv
          update_def(cur_function)
        end
        ui.markdown("&#160;")
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

    ui.markdown("&#160;\r\n\r\n---\r\n\r\n&#160;")
    if ui.button("Open Documentation") then
      love.system.openURL("https://github.com/TRASEVOL-DOG/Collection/blob/master/game_editor.md#game-editor-api-documentation")
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
      test_game()
    end
    
    if k == 'q' then
      stop_testing()
    end
  end

end


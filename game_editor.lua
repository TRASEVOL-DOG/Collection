--require("sugarcoat/sugarcoat.lua")
local _debug = debug
--sugar.utility.using_package(sugar.S, true)


--local old_love = love
--local new_love = {}
--love = setmetatable({}, {
--  __index = old_love,
--  __newindex = function(t, k, v)
--    if k == "draw" or k == "update" or k == "load" then
--      new_love[k] = v
--    else
--      old_love[k] = v
--    end
--  end
--})

require("framework/framework.lua")

local base_env = copy_table(getfenv(0))
merge_tables(base_env, getfenv(1))


local getfenv, setfenv = getfenv, setfenv
local env_save = getfenv(1)
--new_love.load()
--setfenv(1, env_save)

love.load()


local new_love = {
  load   = love.load,
  update = love.update,
  draw   = love.draw
}

love.load = nil
love.update = nil
love.draw = nil


local game_info = {
  _title         = "<Set a title>",
  _description   = "<Set a short description>",
  _controls      = {},
  _controls_list = {},
  _cursor_info   = nil,
  _id            = nil,
  _published     = false
}

local functions = {
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

local function_list = {
  "[+] new function",
  "_init(difficulty)",
  "_update()",
  "_draw()"
}

local cur_function = functions[1]



local user_info = castle.user.isLoggedIn and castle.user.getMe()
local user_registry

network.async(function()
  user_registry = castle.storage.get("user_registry") or {}
end)

function load_game(id)
  network.async(function()
    data = castle.storage.getGlobal("game_"..id)
    
    game_info = data.game_info
    functions = data.functions
    
    function_list = { "[+] new function" }
    for _,f in ipairs(functions) do
      add(function_list, f.def)
    end
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
    published = game_info._published
  }
  
  local reg_data = {
    title     = game_info._title,
    id        = game_info._id,
    published = game_info._published
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
end

function delete_game(id)
  network.async(function()
    user_registry = castle.storage.get("user_registry") or {}

    for i,d in pairs(user_registry) do
      if d.id == id then
        user_registry[i] = nil
        break
      end
    end
    
    castle.storage.set("user_registry", user_registry)
  end)
  
  network.async(castle.storage.setGlobal, nil, "info_"..id, nil)
  network.async(castle.storage.setGlobal, nil, "game_"..id, nil)
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



local testing
local compile_error
local runtime_error

local ui_panel
function test_game()
  if testing then
    stop_testing()
  end

  local n_env = copy_table(base_env)
  
--  setfenv(love.update, n_env)
--  setfenv(love.draw, n_env)
  
--  setfenv(compile_foo, n_env)

  local env = getfenv(1)
  env_save = copy_table(env)
  
  --env_save._description = "hello"
  
  for _, f in ipairs(functions) do
    compile_foo(f, env)
  end
  
  for k, v in pairs(game_info) do
    env[k] = v
  end
  
  testing = true
  
  runtime_error = nil
  
--  env_save = getfenv(1)

  love.update = new_love.update
  love.draw = new_love.draw
  
--  setfenv(old_love.update, n_env)
--  setfenv(old_love.draw, n_env)

--  _init()
  new_love.load("yes")
  
  log("Now testing.", "O")
end

function stop_testing()
  if not testing then
    return
  end
  
  local env = getfenv(1)
  for k, v in pairs(env) do
    env[k] = env_save[k]
  end
  
  for k, v in pairs(env_save) do
    env[k] = env_save[k]
  end
  
  love.update = nil
  love.draw = nil
  
  castle.uiupdate = ui_panel
  
  log("No longer testing.", "O")
end

function compile_foo(foo, env)
  local code = "function "..foo.def.." "..foo.code.." end"
  
  local env = env or getfenv(1)
  
  local comp, err = load(code, nil, "t", env)
  compile_error = err
  
  if err then
    log(foo.def.." compilation failed: "..err, "X")
  else
    comp()
    env[foo.name] = getfenv(1)[foo.name]
    log("Compiled "..foo.def.."!", "O")
  end
end

catch_logs(function(str)
  if not runtime_error and str:sub(1,3) == "ERR" then
    runtime_error = str:gsub("\n", "`\r\n- `")
  end
end)





local find_foo, new_foo, update_def

local tab, tabs = "Projects", {"Projects", "Game Info", "Code", "Play"}

local ui = castle.ui
function castle.uiupdate()
--  ui.tabs("mainTabs", function()
--    ui.tab("Project", project_panel)
--    ui.tab("Game Info", info_editor)
--    ui.tab("Code", function_editor)
--    ui.tab("Play", testing_ui)
--  end)

  tab = ui.radioButtonGroup("Fake Tabs", tab, tabs, {hideLabel = true})
  
  ui.markdown("---\r\n\r\n")
  
  if tab == "Projects" then
    project_panel()
  elseif tab == "Game Info" then
    info_editor()
  elseif tab == "Code" then
    function_editor()
  elseif tab == "Play" then
    testing_ui()
  end
  

--  ui.markdown("~~~")
--  ui_code = ui.codeEditor("Ui", ui_code)
--  if compile_soon then compile_soon = false compile() end
--  if ui.button("Compile") then compile_soon = true end
--  if ui.button("Open") then load_saved() end
end
ui_panel = castle.uiupdate


function project_panel()

  ui.markdown("Current game:")
  
  ui.box("current_game_box", { border = "2px dotted white", borderRadius = 16, margin = 1, padding = 3 }, function()
    ui.markdown("***"..game_info._title.."***\r\n\r\n*`"..(game_info._id or "Save to generate an ID").."`*\r\n\r\n*"..(game_info._published and "Published" or "Not published").."*")
    if ui.button("[Save game]") then
      save_game()
    end
  end)

  ui.markdown("&#160;\r\n\r\nMy games:")
  
  if not user_registry then
    ui.markdown("Loading data...")
  elseif #user_registry == 0 then
    ui.markdown("*This account has no saved games.*")
  else
    for i,info in ipairs(user_registry) do
      ui.box("game_box_"..i, { border = "2px dotted white", borderRadius = 16, margin = 1, padding = 3 }, function()
        ui.markdown("***"..info.title.."***\r\n\r\n*`"..info.id.."`*\r\n\r\n*"..(info.published and "Published" or "Not published").."*")
        
        if ui.button("[Load game]") then
          load_game(info.id)
        end
        
        if ui.button("[Delete game]", { kind = "danger" }) then
          delete_game(info.id)
        end
      end)
    end
  end
  
end

local allowed_inputs = {"[x]", "right", "down", "left", "up", "A", "B", "cur_x", "cur_y", "cur_lb", "cur_rb" }

function info_editor()
  game_info._title = ui.textInput("Title", game_info._title)
  game_info._description = ui.textInput("Description", game_info._description)

  ui.section("Controls", controls_edit)

  cursor_edit()
end

function controls_edit()
  local list, i = game_info._controls_list, 0
  repeat
    i = i + 1
    local ctrl = list[i] or {}
    
    ui.box("controlsBox"..i, { --[[flexDirection = "row",]] flexDirection = "column-reverse", flexWrap = "wrap", border = "2px dotted grey", borderRadius = 16, margin = 1, padding = 3 }, function()
      local inputs = ctrl.inputs or {}
      
      local nv = ui.textInput("control"..i, ctrl.description or "", {hideLabel = true, placeholder = "[does what?]"})
      
      if nv ~= ctrl.description then
        for _, inp in pairs(inputs) do
          game_info._controls[inp] = nv
        end
      
        ctrl.description = nv
      end
    
    
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
        
        --ui.markdown("&#160;")
      until not inputs[j]
      
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
      info.glyph = flr(ui.numberInput("Glyph", info.glyph, {min = 0, max = 255}))
      info.color_a = flr(ui.numberInput("Color A", info.color_a, {min = 0, max = 29}))
      info.color_b = flr(ui.numberInput("Color B", info.color_b, {min = 0, max = 29}))

      if ui.checkbox("Outline", info.outline ~= nil) then
        info.outline = flr(ui.numberInput("Outline color", info.outline, {min = 0, max = 29}))
      else
        info.outline = nil
      end

      info.point_x = ui.numberInput("Point X", info.point_x, {min = 0, max = 16})
      info.point_y = ui.numberInput("Point Y", info.point_y, {min = 0, max = 16})
      info.angle = ui.numberInput("Angle", info.angle, {min = 0, max = 1, step = 0.05})
    end)
  else
    game_info._cursor_info = nil
  end
end

function function_editor()
local chosen = ui.dropdown("Function", cur_function.def, function_list)
  if chosen ~= cur_function.def then
    if chosen == "[+] new function" then
      cur_function = new_foo()
    else
      cur_function = find_foo(chosen)
    end
  end
  
  ui.markdown("`name`")
  local nv = ui.textInput("name", cur_function.name, {hideLabel = true})
  if nv ~= cur_function.name then
    cur_function.name = nv
    update_def(cur_function)
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
  
  if ui.button("/!\\ Remove function", {kind = "danger"}) then
    del(functions, cur_function)
    cur_function = functions[1]
  end
end

function testing_ui()
  if ui.button("Test!") then
    test_game()
  end
  
  if ui.button("Stop test!") then
    stop_testing()
  end
  
  if runtime_error then
    ui.markdown("`Runtime error:`")
    ui.markdown("`"..runtime_error.."`")
  end
end

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


function love.keypressed(k)
  if k == 'r' then
    test_game()
  end
  
  if k == 'q' then
    stop_testing()
  end
end

log("done!", "O")

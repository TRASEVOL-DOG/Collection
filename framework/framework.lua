-- framework for Collection project
--
--

-- here's some values the framework gives out:
-- - _difficulty : 0 is super easy, 100 should be near-impossible (we'll scale it internally - game 25 would have a difficulty of 100)

-- here's what the player should define (as global)
-- - _palette : table of indexes pointing to which colors you want in the full palette (up to 8)
-- - _controls : table listing the controls you're using in this game
-- - 
-- - _init() : callback called on loading the game
-- - _update() : callback called every frame to update the game
-- - _draw() : callback called every frame to draw the game
--


-- Notes on control system:
-- directions map to arrow keys, WASD, and the controller left stick
-- A and B map to Z and X, enter and rshift, and the controller A and B buttons
-- cursor position is mouse poistion, and/or simulated cursor controlled with controller right stick
-- cursor clics are mouse lb and rb, and controller right bumper and trigger.



-- Todo:
----- glyph function
---
----- forbid all sugar functions except some
---
----- load audio assets
---
----- shader?
---
----- control screen
--- control descriptions are stored in _ctrl_descriptions
---  ^ it goes {{inputs} = "desc"} -> inputs are all the inputs that have the same description
---
----- pause/settings button + panel
---
----- game over screen
---
----- ui bar
---
----- chain up one game to the next
---


if CASTLE_PREFETCH then
  CASTLE_PREFETCH({
    "sugarcoat/sugarcoat.lua",
    "framework/glyphs.png",
    "framework/HungryPro.ttf"
  })
end


require("sugarcoat/sugarcoat")
sugar.utility.using_package(sugar.S, true)


-- forward declarations (local):
local load_palette, load_controls, update_controls
local _ctrl_descriptions, _ctrl_active

function love.load()
  init_sugar("Paku~Boisu!", 192, 128, 3)
  
  load_palette()
  load_png("glyphs", "framework/glyphs.png", { 0x000000, 0xffffff, 0x888888}, true)
  load_font("framework/HungryPro.ttf", 16, "main", true)
  load_controls()
  
  if _init then _init() end
end

function love.update()
  update_controls()

  if _update then _update() end
end

function love.draw()
  if _draw then _draw() end
end


function load_palette()
  local full_palette, palette = {  -- tmp: Lux3K -- actual palette is to-do atm
    0xce3b26, 0xf7872a, 0xfcd56b, 0xe7952e, 
    0xf9b857, 0xf0c209, 0xb16e45, 0xf4b27a, 
    0xf0d89d, 0xf9f5d2, 0x8f4349, 0xffa686, 
    0xfdceab, 0x5cac48, 0x8cce6c, 0xc1ec48, 
    0x060329, 0x1c2833, 0x145041, 0x231618, 
    0x521e23, 0x832121, 0xff804a, 0xe16169, 
    0xee8095, 0x7b3781, 0xb64d75, 0xa07385,
    0x44050b, 0x6d2a41, 0x962c52, 0xe53366, 
    0x6e5657, 0xa7acba, 0xaccdec, 0x1c5c83, 
    0x2ba8b5, 0x46dccd
  }, {}

  if not _palette then _palette = {0, 1, 2, 3, 4, 5, 6, 7} end
  for i,c in ipairs(_palette) do
    palette[i] = full_palette[c]
  end
  
  use_palette(palette)
end


local cur_x, cur_y, m_x, m_y = 0, 0, 0, 0
local s_btn, s_btnv = btn, btnv
function update_controls()
  for k, d in pairs(_ctrl_active) do
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
        m_y, d.value = n_y, n_y
        d.state = true
      end
    else
      d.value = s_btnv(k)
      d.state = s_btn(k)
    end
  end
end

function btn(k)
  local d = _ctrl_active[k]
  return d and d.state
end

function btnp(k)
  local d = _ctrl_active[k]
  return d and d.state and not d.pstate
end

function btnr(k)
  local d = _ctrl_active[k]
  return d and d.pstate and not d.state
end

function btnv(k)
  local d = _ctrl_active[k]
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
  
  _ctrl_descriptions, _ctrl_active = {}, {}
  
  for k, desc in pairs(_controls) do
    local b = true
    for _,v in pairs(_ctrl_descriptions) do
      if v[2] == desc then
        b = false
        add(v[1], k)
      end
    end
    
    if b then
      add(_ctrl_descriptions, { {k}, desc})
    end
    
    _ctrl_active[k] = { state = false, pstate = false, value = 0}
    
    register_btn(k, 0, bindings[k])
    
    if k == "left" or k == "right" then
      register_btn("lx_axis", 0, bindings.lx_axis)
    end
    
    if k == "up" or k == "down" then
      register_btn("ly_axis", 0, bindings.ly_axis)
    end
    
    if k == "cur_x" then
      register_btn("rx_axis", 0, bindings.rx_axis)
    end
    
    if k == "cur_y" then
      register_btn("ry_axis", 0, bindings.ry_axis)
    end
  end
end


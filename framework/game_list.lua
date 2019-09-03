
local _game_list = {

  {name       = "Shooting Range",   
   code_name  = "shooting_range",   
   player_spr = 0x20,
  },
  
  {name       = "Speed PlumberZ",   
   code_name  = "speed_plumberz",  
   player_spr = 0x4C,
  },
  
  {name       = "Bar Invaders",   
   code_name  = "tosser",  
   player_spr = 0x60,
  },
  
  {name       = "Candy Hunt",   
   code_name  = "yam",  
   player_spr = 0x62,
  },
  
  {name       = "Tangle",
   code_name  = "tangle",
   player_spr = 0x50
  },
  
  {name       = "Rocky Fishing",
   code_name  = "fishing",
   player_spr = 0x22
  }
}

local _list_games = {}
for _, d in pairs(_game_list) do
  _list_games[d.code_name] = true
end

-- a copy of game_list that will be given when list will be read (security purpose + no need to copy table every frame or to store copy in games)
local _game_list_copy = {}

function get_path_from_id(game_id)
  if not game_id then return end
  return "https://raw.githubusercontent.com/TRASEVOL-DOG/Collection/master/" .. _game_list[game_id].code_name..".castle"  
end

function get_path_from_code_name(code_name)
  return "https://raw.githubusercontent.com/TRASEVOL-DOG/Collection/master/"..code_name..".castle"  
end
  
function get_id_from_code_name(game_code_name)
  if not game_code_name then return end
  for ind, game in pairs(_game_list) do
    if game.code_name == game_code_name then return ind end  
  end  
end

function reset_game_list_copy()
  _game_list_copy = copy_table(_game_list)
end

function get_game_list()
  return _game_list_copy
end

function get_games(count)
  local editor_n = castle.storage.getGlobal("published_count") or 0
  local list_n = #_game_list
  local total = editor_n + list_n
  
  local result = {}
  local already_done = {}
  
  for i = 1, count do
    local n

    ::get_another_game::
    
    repeat
      n = irnd(total)
    until not already_done[n]
    
    already_done[n] = true
    
    if n < editor_n then
      local id = castle.storage.getGlobal("published_"..n)
      
      if not id then
        goto get_another_game
      end
      
      local info = castle.storage.getGlobal("info_"..id)
      
      local data = {
        editor      = true,
        id          = id,
        name        = info.title,
        author      = info.author,
        preview_url = info.preview,
        player_spr  = info.glyph
      }
      
      add(result, data)
    else
      local data = copy_table(_game_list_copy[n - editor_n + 1])
      data.preview_url = "https://raw.githubusercontent.com/TRASEVOL-DOG/Collection/master/"..data.code_name.."_preview.png"
      
      add(result, data)
    end
    
  end
  
  return result
end


function load_game(key, loading_with_code_name, params)
  local path

  if loading_with_code_name then 
    if _list_games[key] then
      path = get_path_from_code_name(key)
    else
      path = "ll4uzw" -- game editor castle ID
      
      if not params then params = {} end
      params.id = key
      params.play = true
    end
    
  else
    path = get_path_from_id(key)
  end
  
  if path then  
    castle.game.load(
        path, 
        params
    )    
  end
end

return load_game
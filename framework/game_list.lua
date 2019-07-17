
_game_list = {

  {name       = "Shooting Range",   
   code_name  = "shooting_range",   
   player_spr = 0x30,
  },
  {name       = "Game Template",   
   code_name  = "game_template",   
   player_spr = 0x30,
  },
  {name       = "Game Template 2",   
   code_name  = "game_template2",  
   player_spr = 0x30,
  },
  
}

-- a copy of game_list that will be given when list will be read (security purpose + no need to copy table every frame or to store copy in games)
_game_list_copy = {}

function get_path_from_id(game_id)
  if not game_id then return end
  return "https://raw.githubusercontent.com/TRASEVOL-DOG/Collection/master/" .. _game_list[game_id].code_name..".castle"  
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

function load_game(key, loading_with_code_name, params)

  local path
    
  if loading_with_code_name then 
    path = get_path_from_id(get_id_from_code_name(key)) 
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
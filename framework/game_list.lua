
_game_list = {

  {name       = "Fishing Game",   
   path       = "https://raw.githubusercontent.com/TRASEVOL-DOG/Collection/master/fishing_game.castle",
   player_spr = 0x30,
   preview    = "fishing_game_preview.png",
  },
  {name       = "Game Template",   
   path       = "https://raw.githubusercontent.com/TRASEVOL-DOG/Collection/master/game_template.castle",
   player_spr = 0x30,
   preview    = "game_template_preview.png",
  },
  {name       = "Game Template 2",   
   path       = "https://raw.githubusercontent.com/TRASEVOL-DOG/Collection/master/game_template2.castle",
   player_spr = 0x30,
   preview    = "game_template2_preview.png",
  },
  
}

-- a copy of game_list that will be given when list will be read (security purpose + no need to copy table every frame or to store copy in games)
_game_list_copy = {}

function get_path_from_id(game_id)
  if not game_id then return end
  return _game_list[game_id].path  
end
  
function get_id_from_name(game_name)
  if not game_name then return end
  for ind, game in pairs(_game_list) do
    if game.name == game_name then return ind end  
  end  
end

function reset_game_list_copy()
  _game_list_copy = copy_table(_game_list)
end

function get_game_list()
  return _game_list_copy
end

function load_game(key, loading_with_name, params)

  local path
    
  if loading_with_name then 
    path = get_path_from_id(get_id_from_name(key)) 
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
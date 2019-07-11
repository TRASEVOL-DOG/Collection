
_game_list = {
  {name = "fishing_game", path = "https://raw.githubusercontent.com/TRASEVOL-DOG/Collection/master/fishing_game.lua"},
  {name = "game_template", path = "https://raw.githubusercontent.com/TRASEVOL-DOG/Collection/master/game_template.lua"},
  {name = "game_template2", path = "https://raw.githubusercontent.com/TRASEVOL-DOG/Collection/master/game_template2.lua"}
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
  return copy_game_list
end
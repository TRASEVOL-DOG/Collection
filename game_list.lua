
_game_list = {
  {name = "fishing_game", path = "https://raw.githubusercontent.com/EliottmacR/framework_collection/master/fishing_game.lua"}
  {name = "game_template", path = "https://raw.githubusercontent.com/EliottmacR/framework_collection/master/fishing_game.lua"}
}

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

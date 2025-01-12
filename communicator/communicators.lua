function communicator.register_communicator(name, def)
  if (def.chargable == nil) then
    def.chargable = false
  end
  
  def.name = name
  def.groups = def.groups or {}
  def.groups.communicator = def.groups.communicator or 1
  def.channel = def.channel or "unknown"
  def.communicator_commands = def.communicator_commands or {}
  def.communicator_command_presets = def.communicator_command_presets or {}
  
  --Register craft
  if def.craft ~= nil then
    minetest.register_craft(def.craft)
  end
  
  --Add command presets
  def = communicator.apply_cmd_presets(def)
  
  --Add default commands to the communicator.
  def.communicator_commands.help = {
    description = "Lists all commands for the communicator.",
    func = function(name)
      minetest.chat_send_player(name,"Commands for: "..(def.description or ""))
      for cmd,t in pairs(def.communicator_commands) do
        minetest.chat_send_player(name,cmd.." "..(t.params or "").." | "..(t.description or ""))
      end
    end
  }
  
  --register it as a communicator
  communicator.registered_communicators[name] = def
  
  --register it as a morpher
  if def.register_morpher == true then
	def.register_item = false
	morphinggrid.register_morpher(name, def)
  elseif def.register_griditem == true then
    def.register_item = false
	def.is_griditem = true
	morphinggrid.register_griditem(name, def)
  end
  
  --register item
  minetest.register_tool(name, def)
end

function communicator.apply_cmd_presets(cmc)
  for pname, p in pairs(cmc.communicator_command_presets) do
    if communicator.cmd_presets[pname] ~= nil then
      if p == true then
        for cname, c in pairs(communicator.cmd_presets[pname]) do
          cmc.communicator_commands[cname] = c
        end
      end
    else
      error("'"..pname.."' is not an existing preset.")
    end
  end
  return cmc
end

minetest.register_on_joinplayer(function(player)
  local _inv = player:get_inventory()
  _inv:set_size("communicators", 4*14)
  _inv:set_size("communicators_main", 1*1)

  --new inventory location
  local player_name = player:get_player_name()
  local inv = minetest.create_detached_inventory("communicators_"..player_name, {
    on_move = function(_, _, _, _, _, _, player)
      communicator.save_inventory(player)
    end,
    
    on_put = function(_, _, _, _, player)
      communicator.save_inventory(player)
    end,
    
    on_take = function(_, _, _, _, player)
      communicator.save_inventory(player)
    end,
    
    allow_put = function(_, _, _, stack, _)
      local itemstring = stack:get_name()
      if communicator.registered_communicators[itemstring] then
        return stack:get_count()
      end
      return 0
    end
  })

  inv:set_size("single", 1*1)
  inv:set_size("main", 4*14)

  communicator.restore_inventory(player)
end)

function communicator.get_inventory(player)
  return minetest.get_inventory({ type="detached", name="communicators_"..player:get_player_name() })
end

function communicator.save_inventory(player)
  local _inv = player:get_inventory()
  local inv = communicator.get_inventory(player)
  _inv:set_list("communicators_main", inv:get_list("single"))
  _inv:set_list("communicators", inv:get_list("main"))
end

function communicator.restore_inventory(player)
  local _inv = player:get_inventory()
  local inv = communicator.get_inventory(player)
  inv:set_list("single", _inv:get_list("communicators_main"))
  inv:set_list("main", _inv:get_list("communicators"))
end

function communicator.ui(player)
  local inventory_location = "communicators_"..player
  local formspec = "size[14,12]"..
    "label[4,0;Place a communicator in the single communicator slot and use it with the communicator chat commands.]"..
    "list[detached:"..inventory_location..";single;6.25,0.5;1,1;]"..
    "list[detached:"..inventory_location..";main;0,2;14,4;]"..
    "list[current_player;main;3,7.5;8,4;]"
  return formspec
end

minetest.register_chatcommand("communicators", {
  params = "",
  description = "Shows a player's communicator inventory.",
    
  privs = {
    interact = true,
    power_rangers = true,
    communicator = true
  },
  
  func = function(name)
    minetest.show_formspec(name, name.."_communicators", communicator.ui(name))
  end
})

--Grid Documentation
morphinggrid.grid_doc.register_type("communicators", {
	description = "Communicators",
	
	formspec = function(player, itemstring)
		local itemdef = minetest.registered_items[itemstring]
		local player_name = player:get_player_name()
		local inv = morphinggrid.grid_doc.get_inventory(player)
		local grid_doc_def = itemdef.grid_doc or {}
		local recipe_status = ""
		
		morphinggrid.grid_doc.clear_lists(player)
		inv:set_stack("item", 1, itemstring)
		
		local craft = minetest.get_craft_recipe(itemstring) --input.method input.items
		if craft.items then
			if craft.method == "normal" then
				inv:set_list("recipe", craft.items)
			end
			recipe_status = "Recipe:"
		else
			recipe_status = "(No Recipe)"
		end
		
		local f = "label[5.4,2.3;Name: "..(itemdef.description or itemstring).."]"..
		"label[5.4,2.8;Item String: "..itemstring.."]"..
		"style[description;border=false]"..
		"box[5.4,7.8;14.4,5;#0f0f0f]"..
		"textarea[5.4,7.8;14.4,5;description;;"..(grid_doc_def.description or "No description.").."]"..
		"list[detached:"..player_name.."_grid_doc;recipe;5.4,3.8;3,3;0]"..
		"list[detached:"..player_name.."_grid_doc;item;5.4,0.6;1,1;0]"..
		"label[5.4,0.4;Item:]"..
		"label[5.4,3.6;"..recipe_status.."]"
		
		return f
	end,
	
	get_items = function()
		local t = {}
		for k, v in pairs(communicator.registered_communicators) do
			table.insert(t, {desc=v.description or k, name=k, data={k}})
		end
		table.sort(t, function(a,b) return a.name < b.name end)
		return t
	end,
	
	filter = function(text, itemstring)
		local item = minetest.registered_items[itemstring]
		if string.find(itemstring, text) or string.find(item.description or itemstring, text) then
			return true
		end
		return false
	end
})
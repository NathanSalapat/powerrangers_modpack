--local S = armor_i18n.gettext

morphinggrid.registered_rangertypes = {}
rangertype = {}

function morphinggrid.register_rangertype(name, rangertypedef)
  rangertypedef.name = name
  rangertypedef.weapons = rangertypedef.weapons or {}
  morphinggrid.registered_rangertypes[name] = rangertypedef
  --table.insert(morphinggrid.registered_rangertypes, rangertypedef)
end

function morphinggrid.get_rangertype(name)
  for i, v in pairs(morphinggrid.registered_rangertypes) do
    if v.name == name then
      return v
    end
  end
  return nil
end

function morphinggrid.get_registered_rangertypes()
  return morphinggrid.registered_rangertypes
end

morphinggrid.registered_rangers = {}
morphinggrid.registered_morphers = {}
ranger = {}

morphinggrid.registered_ranger_after_morphs = {}
morphinggrid.registered_ranger_after_demorphs = {}

function morphinggrid.register_ranger(name, rangerdef)
  local name_ = morphinggrid.split_string (name, ":")
  rangerdef.name = name
  
  --make sure fields are not nil
  rangerdef.ranger_groups = rangerdef.ranger_groups or {}
  rangerdef.abilities = rangerdef.abilities or {}
  
  if rangerdef.hide_identity == nil then rangerdef.hide_identity = true end
  if rangerdef.hide_player == nil then rangerdef.hide_player = false end
  if rangerdef.create_rangerdata == nil then rangerdef.create_rangerdata = true end
  
  --textures
  rangerdef.armor_textures = morphinggrid.correct_armor_textures(rangerdef)
  
  --Register Armor
  register_ranger_armor(rangerdef)
  
  --ranger commands
  rangerdef.ranger_commands = rangerdef.ranger_commands or {}
  
  --Add command presets
  rangerdef.ranger_command_presets = rangerdef.ranger_command_presets or {}
  for pname, p in pairs(rangerdef.ranger_command_presets) do
	if morphinggrid.ranger_cmd_presets[pname] then
		if p == true then
			for cname, c in pairs(morphinggrid.ranger_cmd_presets[pname]) do
			  rangerdef.ranger_commands[cname] = c
			end
		end
	else
		error("'"..pname.."' is not an existing preset.")
	end
  end
  
  --add help command
  rangerdef.ranger_commands.help = {
    description = "Lists all commands for the ranger.",
    func = function(name)
      minetest.chat_send_player(name,"Commands for: "..(rangerdef.description or name))
      for cmd,t in pairs(rangerdef.ranger_commands) do
        minetest.chat_send_player(name,cmd.." "..(t.params or "").." | "..(t.description or name))
      end
    end
  }
  
  if rangerdef.morpher ~= nil then
    local morpherdef = rangerdef.morpher
    
    --Morpher
    morpherdef.ranger = rangerdef.name
    morpherdef.type = morpherdef.type or "craftitem"
    morphinggrid.register_morpher(morpherdef.name, morpherdef)
    
    --Register morpher craft
    if morpherdef.recipe ~= nil then
      local recipe = morpherdef.recipe
      recipe.output = morpherdef.name
      minetest.register_craft(morpherdef.recipe)
    end
  end
  
  --register after morph callback
  if rangerdef.after_morph ~= nil then
    table.insert(morphinggrid.registered_ranger_after_morphs, name)
  end
  
  if rangerdef.after_demorph ~= nil then
    table.insert(morphinggrid.registered_ranger_after_demorphs, name)
  end
  
  --Add to table
  morphinggrid.registered_rangers[rangerdef.name] = rangerdef
  --table.insert(morphinggrid.registered_rangers, rangerdef)
  
  --Load connection
  local connection = minetest.deserialize(morphinggrid.mod_storage.get_string(name.."_connection"))
  morphinggrid.connections[name] = connection
  
  morphinggrid.connections[name] = morphinggrid.connections[name] or {}
  morphinggrid.connections[name].name = name
  morphinggrid.connections[name].players = morphinggrid.connections[name].players or {}
  
  --register rangerdata
  morphinggrid.register_griditem(name.."_rangerdata", {
	inventory_image = "rangerdata.png",
	description = (rangerdef.description or name).." Ranger Data",
	groups = { not_in_creative_inventory = 1 },
	grid_doc = {
		hidden = true
	}
  })
end

function register_ranger_armor(rangerdef)
  local modname = morphinggrid.split_string (rangerdef.name, ":")[1]
  local ranger = morphinggrid.split_string (rangerdef.name, ":")[2]
  
  --helmet
  armor:register_armor(modname..":helmet_"..ranger, {
    --description = S(rangerdef.description.." Helmet"),
	description = rangerdef.description.." Helmet",
    texture = rangerdef.armor_textures.helmet.armor,
    preview = rangerdef.armor_textures.helmet.preview,
    inventory_image = rangerdef.armor_textures.helmet.inventory,
    armor_fire_protect = true,
    armor_punch_damage = true,
    armor_groups = {fleshy=100},
    groups = {armor_head=1, armor_heal=rangerdef.heal, armor_use=rangerdef.use, armor_water=1,
      not_in_creative_inventory=1},
      
    on_destroy = function(player, index, stack)
      local morph_status = morphinggrid.get_morph_status(player)
      local morph_status_ranger = morphinggrid.registered_rangers[morph_status]
      if morph_status ~= nil then
        morphinggrid.demorph(player, { voluntary = false, chat_messages = false })
        local connection = morphinggrid.connections[modname..":"..ranger].players[player:get_player_name()]
        connection.damage = connection.damage or 12
        connection.armor_wear = 65535
        local timer_amount = 60 * (connection.damage/12)
        connection.timer = timer_amount
        minetest.chat_send_player(player:get_player_name(), "You have demorphed becuase you did not have enough power. (Ranger: "..morph_status_ranger.description..")")
      end
    end,
    
    on_equip = function(player, index, stack)
      local current_armor = morphinggrid.get_current_armor(player, rangerdef.name)
      if current_armor.chestplate and current_armor.leggings and current_armor.boots then
        local ranger = morphinggrid.registered_rangers[rangerdef.name]
        
        local morph_status = morphinggrid.get_morph_status(player)
        if morph_status == nil then
          local result, morph_info = morphinggrid.morph(player, ranger, { armor_parts = current_armor })
          
          if morph_info.reason == "no_permission" then
            clear_ranger_armor(player, rangerdef.name)
          end
        end
      end
    end,
    
    on_unequip = function(player, index, stack)
      local current_armor = morphinggrid.get_current_armor(player, rangerdef.name)
      if not current_armor.helmet and not current_armor.chestplate and not current_armor.leggings and not current_armor.boots then
        local morph_status = morphinggrid.get_morph_status(player)
        if morph_status ~= nil then
          morphinggrid.demorph(player, {priv_bypass=true})
        end
      end
    end,
    
    on_punched = function(player, hitter, time_from_last_punch, tool_capabilities)
      local caps = tool_capabilities or {}
      local damage_groups = caps.damage_groups or {fleshy = 0}
      morphinggrid.punch_ranger_armor(player, hitter, damage_groups.fleshy)
      morphinggrid.hud_update_power_usage(player)
    end,
    
    on_drop = function(itemstack, dropper, pos)
      return
    end,
  })
  
  --chestplate
  armor:register_armor(modname..":chestplate_"..ranger, {
    --description = S(rangerdef.description.." Chestplate"),
	description = rangerdef.description.." Chestplate",
    texture = rangerdef.armor_textures.chestplate.armor,
    preview = rangerdef.armor_textures.chestplate.preview,
    inventory_image = rangerdef.armor_textures.chestplate.inventory,
    armor_groups = {fleshy=100},
    groups = {armor_torso=1, armor_heal=rangerdef.heal, armor_use=rangerdef.use,
      not_in_creative_inventory=1},
      
    on_destroy = function(player, index, stack)
      local morph_status = morphinggrid.get_morph_status(player)
      local morph_status_ranger = morphinggrid.registered_rangers[morph_status]
      if morph_status ~= nil then
        morphinggrid.demorph(player, { voluntary = false, chat_messages = false })
        local connection = morphinggrid.connections[modname..":"..ranger].players[player:get_player_name()]
        connection.damage = connection.damage or 12
        connection.armor_wear = 65535
        local timer_amount = 60 * (connection.damage/12)
        connection.timer = timer_amount
        minetest.chat_send_player(player:get_player_name(), "You have demorphed becuase you did not have enough power. (Ranger: "..morph_status_ranger.description..")")
      end
    end,
    
    on_equip = function(player, index, stack)
      local current_armor = morphinggrid.get_current_armor(player, rangerdef.name)
      if current_armor.chestplate and current_armor.leggings and current_armor.boots then
        local ranger = morphinggrid.registered_rangers[rangerdef.name]
        
        local morph_status = morphinggrid.get_morph_status(player)
        if morph_status == nil then
          local result, morph_info = morphinggrid.morph(player, ranger, { armor_parts = current_armor })
          
          if morph_info.reason == "no_permission" then
            clear_ranger_armor(player, rangerdef.name)
          end
        end
      end
    end,
    
    on_unequip = function(player, index, stack)
      local current_armor = morphinggrid.get_current_armor(player, rangerdef.name)
      
      if not current_armor.helmet and not current_armor.chestplate and not current_armor.leggings and not current_armor.boots then
        local morph_status = morphinggrid.get_morph_status(player)
        if morph_status ~= nil then
          morphinggrid.demorph(player, {priv_bypass=true})
        end
      end
    end,
    
    on_punched = function(player, hitter, time_from_last_punch, tool_capabilities)
      local caps = tool_capabilities or {}
      local damage_groups = caps.damage_groups or {fleshy = 0}
      morphinggrid.punch_ranger_armor(player, hitter, damage_groups.fleshy)
      morphinggrid.hud_update_power_usage(player)
    end,
    
    on_drop = function(itemstack, dropper, pos)
      return
    end,
  })
  
  --leggings
  armor:register_armor(modname..":leggings_"..ranger, {
    --description = S(rangerdef.description.." Leggings"),
	description = rangerdef.description.." Leggings",
    texture = rangerdef.armor_textures.leggings.armor,
    preview = rangerdef.armor_textures.leggings.preview,
    inventory_image = rangerdef.armor_textures.leggings.inventory,
    armor_fire_protect = true,
    armor_punch_damage = true,
    armor_groups = {fleshy=100},
    groups = {armor_legs=1, armor_heal=rangerdef.heal, armor_use=rangerdef.use,
      not_in_creative_inventory=1},
      
    on_destroy = function(player, index, stack)
      local morph_status = morphinggrid.get_morph_status(player)
      local morph_status_ranger = morphinggrid.registered_rangers[morph_status]
      if morph_status ~= nil then
        morphinggrid.demorph(player, { voluntary = false, chat_messages = false })
        local connection = morphinggrid.connections[modname..":"..ranger].players[player:get_player_name()]
        connection.damage = connection.damage or 12
        connection.armor_wear = 65535
        local timer_amount = 60 * (connection.damage/12)
        connection.timer = timer_amount
        minetest.chat_send_player(player:get_player_name(), "You have demorphed becuase you did not have enough power. (Ranger: "..morph_status_ranger.description..")")
      end
    end,
    
    on_equip = function(player, index, stack)
      local current_armor = morphinggrid.get_current_armor(player, rangerdef.name)
      if current_armor.chestplate and current_armor.leggings and current_armor.boots then
        local ranger = morphinggrid.registered_rangers[rangerdef.name]
        
        local morph_status = morphinggrid.get_morph_status(player)
        if morph_status == nil then
          local result, morph_info = morphinggrid.morph(player, ranger, { armor_parts = current_armor })
          
          if morph_info.reason == "no_permission" then
            clear_ranger_armor(player, rangerdef.name)
          end
        end
      end
    end,
    
    on_unequip = function(player, index, stack)
      local current_armor = morphinggrid.get_current_armor(player, rangerdef.name)
      
      if not current_armor.helmet and not current_armor.chestplate and not current_armor.leggings and not current_armor.boots then
        local morph_status = morphinggrid.get_morph_status(player)
        if morph_status ~= nil then
          morphinggrid.demorph(player, {priv_bypass=true})
        end
      end
    end,
    
    on_punched = function(player, hitter, time_from_last_punch, tool_capabilities)
      local caps = tool_capabilities or {}
      local damage_groups = caps.damage_groups or {fleshy = 0}
      morphinggrid.punch_ranger_armor(player, hitter, damage_groups.fleshy)
      morphinggrid.hud_update_power_usage(player)
    end,
    
    on_drop = function(itemstack, dropper, pos)
      return
    end,
  })
  
  --boots
  armor:register_armor(modname..":boots_"..ranger, {
    --description = S(rangerdef.description.." Boots"),
	description = rangerdef.description.." Boots",
    texture = rangerdef.armor_textures.boots.armor,
    preview = rangerdef.armor_textures.boots.preview,
    inventory_image = rangerdef.armor_textures.boots.inventory,
    armor_fire_protect = true,
    armor_punch_damage = true,
    armor_groups = {fleshy=100},
    groups = {armor_feet=1, armor_heal=rangerdef.heal, armor_use=rangerdef.use,
      not_in_creative_inventory=1},
      
    on_destroy = function(player, index, stack)
      local morph_status = morphinggrid.get_morph_status(player)
      local morph_status_ranger = morphinggrid.registered_rangers[morph_status]
      if morph_status ~= nil then
        morphinggrid.demorph(player, { voluntary = false, chat_messages = false })
        local connection = morphinggrid.connections[modname..":"..ranger].players[player:get_player_name()]
        connection.damage = connection.damage or 12
        connection.armor_wear = 65535
        local timer_amount = 60 * (connection.damage/12)
        connection.timer = timer_amount
        minetest.chat_send_player(player:get_player_name(), "You have demorphed becuase you did not have enough power. (Ranger: "..morph_status_ranger.description..")")
      end
    end,
    
    on_equip = function(player, index, stack)
      local current_armor = morphinggrid.get_current_armor(player, rangerdef.name)
      if current_armor.chestplate and current_armor.leggings and current_armor.boots then
        local ranger = morphinggrid.registered_rangers[rangerdef.name]
        
        local morph_status = morphinggrid.get_morph_status(player)
        if morph_status == nil then
          local result, morph_info = morphinggrid.morph(player, ranger, { armor_parts = current_armor })
          
          if morph_info.reason == "no_permission" then
            clear_ranger_armor(player, rangerdef.name)
          end
        end
      end
    end,
    
    on_unequip = function(player, index, stack)
      local current_armor = morphinggrid.get_current_armor(player, rangerdef.name)
      
      if not current_armor.helmet and not current_armor.chestplate and not current_armor.leggings and not current_armor.boots then
        local morph_status = morphinggrid.get_morph_status(player)
        if morph_status ~= nil then
          morphinggrid.demorph(player, {priv_bypass=true})
        end
      end
    end,
    
    on_punched = function(player, hitter, time_from_last_punch, tool_capabilities)
      local caps = tool_capabilities or {}
      local damage_groups = caps.damage_groups or {fleshy = 0}
      morphinggrid.punch_ranger_armor(player, hitter, damage_groups.fleshy)
      morphinggrid.hud_update_power_usage(player)
    end,
    
    on_drop = function(itemstack, dropper, pos)
      return
    end,
  })
end

function clear_ranger_armor(player, ranger_name)
  local modname = morphinggrid.split_string (ranger_name, ":")[1]
  local ranger = morphinggrid.split_string (ranger_name, ":")[2]
  
  local inv = minetest.get_inventory({type="detached", name=player:get_player_name().."_armor"})
  
  inv:remove_item("armor", ItemStack(modname..":helmet_"..ranger.." 2"))
  inv:remove_item("armor", ItemStack(modname..":chestplate_"..ranger.." 2"))
  inv:remove_item("armor", ItemStack(modname..":leggings_"..ranger.." 2"))
  inv:remove_item("armor", ItemStack(modname..":boots_"..ranger.." 2"))
  
  armor:save_armor_inventory(player)
  armor:set_player_armor(player)
end

function morphinggrid.get_current_armor(player, ranger_name)
  local t = { helmet = false, chestplate = false, leggings = false, boots = false }
  
  local player_name = player:get_player_name()
  local modname = morphinggrid.split_string (ranger_name, ":")[1]
  local ranger = morphinggrid.split_string (ranger_name, ":")[2]
  
  local inv = minetest.get_inventory({type="detached", name=player_name.."_armor"})
  
  if inv:contains_item("armor", ItemStack(modname..":helmet_"..ranger)) then
    t.helmet = true
  end
  
  if inv:contains_item("armor", ItemStack(modname..":chestplate_"..ranger)) then
    t.chestplate = true
  end
  
  if inv:contains_item("armor", ItemStack(modname..":leggings_"..ranger)) then
    t.leggings = true
  end
  
  if inv:contains_item("armor", ItemStack(modname..":boots_"..ranger)) then
    t.boots = true
  end
  
  return t
end

function morphinggrid.correct_armor_textures(rangerdef)
  local name_ = morphinggrid.split_string (rangerdef.name, ":")
  
  --armor_textures and it's 'named'contents cannot be nil otherwise and exception will be thrown.
  if rangerdef.armor_textures == nil then
    rangerdef.armor_textures = {}
  end
  
  
  if rangerdef.armor_textures.helmet == nil then
    rangerdef.armor_textures.helmet = {}
  end
  
  if rangerdef.armor_textures.chestplate == nil then
    rangerdef.armor_textures.chestplate = {}
  end
  
  if rangerdef.armor_textures.leggings == nil then
    rangerdef.armor_textures.leggings = {}
  end
  
  if rangerdef.armor_textures.boots == nil then
    rangerdef.armor_textures.boots = {}
  end
  
  
  --auto-generate file names if not specified.
  rangerdef.armor_textures = {
    helmet = {
        armor = rangerdef.armor_textures.helmet.armor or name_[1].."_helmet_"..name_[2],
        armor_visor_mask = rangerdef.armor_textures.helmet.armor_visor_mask,
        preview = rangerdef.armor_textures.helmet.preview or name_[1].."_helmet_"..name_[2].."_preview.png",
        inventory = rangerdef.armor_textures.helmet.inventory or name_[1].."_inv_helmet_"..name_[2]..".png"
      },
      
    chestplate = {
        armor = rangerdef.armor_textures.chestplate.armor or name_[1].."_chestplate_"..name_[2],
        preview = rangerdef.armor_textures.chestplate.preview or name_[1].."_chestplate_"..name_[2].."_preview.png",
        inventory = rangerdef.armor_textures.chestplate.inventory or name_[1].."_inv_chestplate_"..name_[2]..".png"
      },
      
    leggings = {
        armor = rangerdef.armor_textures.leggings.armor or name_[1].."_leggings_"..name_[2],
        preview = rangerdef.armor_textures.leggings.preview or name_[1].."_leggings_"..name_[2].."_preview.png",
        inventory = rangerdef.armor_textures.leggings.inventory or name_[1].."_inv_leggings_"..name_[2]..".png"
      },
      
    boots = {
        armor = rangerdef.armor_textures.boots.armor or name_[1].."_boots_"..name_[2],
        preview = rangerdef.armor_textures.boots.preview or name_[1].."_boots_"..name_[2].."_preview.png",
        inventory = rangerdef.armor_textures.boots.inventory or name_[1].."_inv_boots_"..name_[2]..".png"
      }
  }
  
  return rangerdef.armor_textures
end

function morphinggrid.get_ranger(name)
  for i, v in pairs(morphinggrid.registered_rangers) do
    if v.name == name then
      return v
    end
  end
  return nil
end

function morphinggrid.get_registered_rangers()
  return morphinggrid.registered_rangers
end

function morphinggrid.get_ranger_group(ranger, group)
  if type(ranger) == "string" then
    ranger = morphinggrid.get_ranger(ranger)
  end
  if ranger ~= nil then
    local v = ranger.ranger_groups[group]
    if v ~= nil then
      return v
    end
  end
  return 0
end

function morphinggrid.punch_ranger_armor(player, hitter, damage)
  local ranger_name = morphinggrid.get_morph_status(player)
  local ranger = morphinggrid.registered_rangers[ranger_name]
  damage = damage or 1
  
  if ranger ~= nil then
    local inv = minetest.get_inventory({
      type="detached", name=player:get_player_name().."_armor"})
    
    local list = inv:get_list("armor")
    for i, stack in pairs(list) do
      local old_stack = ItemStack(stack)
      local amount_of_damage = damage * ranger.use
      local wear_level = 65535 - (stack:get_wear() + amount_of_damage)
      
      stack:add_wear(amount_of_damage)
      inv:set_stack("armor", i, stack)
      
      morphinggrid.connections[ranger.name].players[player:get_player_name()] = morphinggrid.connections[ranger.name].players[player:get_player_name()] or { timer = 0 }
      morphinggrid.connections[ranger.name].players[player:get_player_name()].damage = wear_level
      
      if stack:get_count() == 0 then
        armor:run_callbacks("on_destroy", player, i, old_stack)
      end
      
      armor:save_armor_inventory(player)
      armor:set_player_armor(player)
    end
  end
end

function ranger.get_rangertype(rangerdef)
  local rangertype_string = morphinggrid.split_string(rangerdef.name, ":")[1]
  for _, rt in pairs(morphinggrid.rangertypes) do
    if rt.name == rangertype_string then
      return rt
    end
  end
  return nil
end

function ranger.get_ranger(rangerdef)
  return morphinggrid.split_string(rangerdef.name, ":")[2]
end

local function deepCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			v = deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

--Morpher
function morphinggrid.register_morpher(name, morpherdef)
  morpherdef.name = name
  morpherdef.type = morpherdef.type or "craftitem"
  morpherdef.morpher_commands = morpherdef.morpher_commands or {}
  morpherdef.groups = morpherdef.groups or {}
  morpherdef.groups.morpher = morpherdef.groups.morpher or 1
  morpherdef.griditems = morpherdef.griditems or {}
  
  morpherdef.allow_prevent_respawn = morpherdef.allow_prevent_respawn or function(player, itemstack)
	return morphinggrid.default_callbacks.morpher.allow_prevent_respawn(player, itemstack)
  end
  
  --configure if the morpher is supposed to morph a player. This should be false if a morpher does not have a connection to the morphinggrid.
  --This is set to 'true' by default. If the morpher has no connection, the 'morphing' functionality will not be registered.
  if type(morpherdef.has_connection) ~= "boolean" then
	morpherdef.has_connection = true
  end
  
  --on_use method. This is what allows the player to morph.
  local save_on_use = morpherdef.on_use
  morpherdef.on_use = function(itemstack, user, pointed_thing)
	if morpherdef.has_connection then
		local grid_params = {
			player = user,
			pos = user:get_pos(),
			itemstack = itemstack
		}
		
		local grid_args = morphinggrid.call_grid_functions("before_morpher_use", grid_params)
		itemstack = grid_params.itemstack
		if not grid_args.cancel then
			if morpherdef.morph_func_override ~= nil then
			  itemstack = morpherdef.morph_func_override(user, itemstack, pointed_thing)
			elseif morpherdef.ranger == nil then
			  --nothing happens. This must be checked to prevent errors but allow for custom modding.
			else
			  local ranger = morphinggrid.get_ranger(morpherdef.ranger)
			  if ranger == nil then
				error("'"..morpherdef.ranger.."' is not a registred ranger.")
			  end
			  morphinggrid.morph(user, ranger, { morpher = name, itemstack = itemstack })
			end
		else
			grid_params.canceled = true
		end
		
		morphinggrid.call_grid_functions("after_morpher_use", grid_params)
		itemstack = grid_params.itemstack
	end
		
	if morpherdef.register_griditem == true then
		local _grid_params = {
			itemstack = itemstack,
			user = user,
			pointed_thing = pointed_thing
		}
		
		local _grid_args = morphinggrid.call_grid_functions("before_grid_item_on_use", _grid_params)
		if not _grid_args.cancel then
			if type(save_on_use) == "function" then
				itemstack = save_on_use(itemstack, user, pointed_thing)
			end
		else
			_grid_params.canceled = true
		end
		
		morphinggrid.call_grid_functions("after_grid_item_on_use", _grid_params)
	else
		if type(save_on_use) == "function" then
			itemstack = save_on_use(itemstack, user, pointed_thing)
		end
	end
		
    return itemstack
  end
  
  --Add command presets
  morpherdef.morpher_command_presets = morpherdef.morpher_command_presets or {}
  for pname, p in pairs(morpherdef.morpher_command_presets) do
	if morphinggrid.morpher_cmd_presets[pname] then
		if p == true then
			for cname, c in pairs(morpherdef.morpher_cmd_presets[pname]) do
			  morpherdef.morpher_commands[cname] = c
			end
		end
	else
		error("'"..pname.."' is not an existing preset.")
	end
  end
  
  --Add default commands to the morpher.
  morpherdef.morpher_commands.help = {
    description = "Lists all commands for the morpher.",
    func = function(name)
      minetest.chat_send_player(name,"Commands for: "..morpherdef.description)
      for cmd,t in pairs(morpherdef.morpher_commands) do
        minetest.chat_send_player(name,cmd.." "..(t.params or "").." | "..(t.description or ""))
      end
    end
  }
  
  if type(morpherdef.morpher_slots) == "table" then
	morpherdef.morpher_commands.slots = {
		description = "Gives access to the morpher's slots.",
		func = function(pname)
			minetest.show_formspec(pname, "morphinggrid:morpher_slots", morphinggrid.morpher_slots.formspec(pname, name))
		end
	}
  end
  
  --get register_item
  local register_item
  if type(morpherdef.register_item) == "boolean" then
	register_item = morpherdef.register_item
  else
	register_item = true
  end
  
  --register it as a morpher
  morphinggrid.registered_morphers[name] = morpherdef
  
  --register it as a griditem
  if morpherdef.register_griditem == true then
	morpherdef.register_item = false
	morpherdef.is_griditem = true
	morpherdef.exclude_callbacks = {on_use=false}
	morphinggrid.register_griditem(name, morpherdef)
  end
  
  --register item
  if register_item == true then
	  local allowed_types = {tool=true,craftitem=true}
	  if not allowed_types[morpherdef.type] then
		error("item type '"..morpherdef.type.."' is invalid.")
	  end
  end
  
  minetest["register_"..morpherdef.type](name, morpherdef)
end

function morphinggrid.morph_from_morpher(player, morpher, itemstack)
    if type(morpher) == "string" then
		if morphinggrid.registered_morphers[morpher] == nil then error("'"..morpher.."' is not a registered morpher.") end
		morpher = morphinggrid.registered_morphers[morpher]
    end
    
	--requrment to be a seable morpher
	if morpher.has_connection then
		local grid_params = {
			player = player,
			pos = player:get_pos(),
			itemstack = itemstack
		}

		local grid_args = morphinggrid.call_grid_functions("before_morpher_use", grid_params)
		itemstack = grid_params.itemstack
		if not grid_args.cancel then
			if morpher.morph_func_override ~= nil then
				itemstack = morpher.morph_func_override(player, itemstack) or itemstack
			elseif morpher.ranger == nil then
				
			else
				local ranger = morphinggrid.registered_rangers[morpher.ranger]
				if ranger == nil then
					error("'"..morpher.ranger.."' is not a registered ranger.")
				end
				morphinggrid.morph(player, ranger, {morpher=morpher.name,itemstack=itemstack})
			end
		else
			grid_params.canceled = true
		end
		
		morphinggrid.call_grid_functions("after_morpher_use", grid_params)
	end
	
    return itemstack
end

function morphinggrid.get_morpher(name)
  return morphinggrid.registered_morphers[name]
end

function morphinggrid.get_morphers()
  return morphinggrid.registered_morphers
end

--default morpher functions
morphinggrid.default_callbacks.morpher = {}

function morphinggrid.default_callbacks.morpher.allow_prevent_respawn(player, itemstack)
	local def = morphinggrid.registered_morphers[itemstack:get_name()]
	
	--if item is a grid item, use it's default callback
	if def.is_griditem then
		return morphinggrid.default_callbacks.griditem.allow_prevent_respawn(player, itemstack)
	end
	
	--if not, continue
	local count = 0
	local rangers = {}
	for i, griditem in ipairs(def.griditems) do
		local griditemdef = morphinggrid.registered_griditems[griditem] or { rangers = {} }
		
		-- minetest.chat_send_all("["..def.name.."].griditems["..(griditem or "(nil)").."]")
		for _, ranger in ipairs(griditemdef.rangers) do
			-- minetest.chat_send_all("["..def.name.."].griditems["..(griditem or "(nil)")..
				-- "].rangers["..(ranger or "(nil)").."]")
		
			count = count + 1
			table.insert(rangers, ranger)
		end
	end
	
	if count < 1 then
		return true
	end
	
	for k, ranger in ipairs(rangers) do
		local connection = morphinggrid.get_connection(player, ranger)
		if connection.timer <= 0 then
			return true
		end
	end
	return false
end
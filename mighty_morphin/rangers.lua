dofile(minetest.get_modpath("morphinggrid") .. "/functions.lua")

morphinggrid.register_rangertype("mighty_morphin", {
  description = "Mighty Morphin",
  weapons = {"mighty_morphin:power_axe", "mighty_morphin:power_bow", "mighty_morphin:power_lance", "mighty_morphin:power_daggers",
            "mighty_morphin:power_sword", "mighty_morphin:dragon_dagger", "mighty_morphin:saba", "mighty_morphin:blade_blaster",
            "mighty_morphin:power_blaster"},
  grid_doc = {
    description = "The Mighty Morphin Power Rangers (MMPR) is a team of rangers that uses Power Coins to obtain their powers."..
    "Power Coins are placed inside of an empty morpher using morpher slots. The green ranger (via Dragonzord Powercoin) "..
    "has a special shield that makes him stronger. The shield can be removed, and given to other rangers of the same team."..
    "When the green ranger was destroyed, the white ranger (via Tigerzord Powercoin) took the green ranger's place."
  }
})

mmprrangers = {
  {"black", "Black", 100, 12, "mastodon", {"mighty_morphin:power_axe", "mighty_morphin:blade_blaster", "mighty_morphin:power_blaster"}, {}},
  {"pink", "Pink", 100, 12, "pterodactyl", {"mighty_morphin:power_bow", "mighty_morphin:blade_blaster", "mighty_morphin:power_blaster"}, {}},
  {"blue", "Blue", 100, 12, "triceratops", {"mighty_morphin:power_lance", "mighty_morphin:blade_blaster", "mighty_morphin:power_blaster"}, {}},
  {"yellow", "Yellow", 100, 12, "saber_toothed_tiger", {"mighty_morphin:power_daggers", "mighty_morphin:blade_blaster", "mighty_morphin:power_blaster"}, {}},
  {"red", "Red", 100, 12, "tyrannosaurus", {"mighty_morphin:power_sword", "mighty_morphin:blade_blaster", "mighty_morphin:power_blaster"}, { leader = 1 }},
  {"green", "Green", 100, 10, "dragonzord", {"mighty_morphin:dragon_dagger", "mighty_morphin:blade_blaster"}, {}},
  {"white", "White", 100, 9, "tigerzord", {"mighty_morphin:saba", "mighty_morphin:blade_blaster"}, { leader = 1 }}
}

mmprrangers_shields = {
  {"black_shield", "Black", 100, 10, {"mighty_morphin:power_axe", "mighty_morphin:dragon_dagger", "mighty_morphin:blade_blaster",
  "mighty_morphin:power_blaster"}, { hidden = 1 }},
  {"pink_shield", "Pink", 100, 10, {"mighty_morphin:power_bow", "mighty_morphin:dragon_dagger", "mighty_morphin:blade_blaster",
  "mighty_morphin:power_blaster"}, { hidden = 1 }},
  {"blue_shield", "Blue", 100, 10, {"mighty_morphin:power_lance", "mighty_morphin:dragon_dagger", "mighty_morphin:blade_blaster",
  "mighty_morphin:power_blaster"}, { hidden = 1 }},
  {"yellow_shield", "Yellow", 100, 10, {"mighty_morphin:power_daggers", "mighty_morphin:dragon_dagger", "mighty_morphin:blade_blaster",
  "mighty_morphin:power_blaster"}, { hidden = 1 }},
  {"red_shield", "Red", 100, 10, {"mighty_morphin:power_sword", "mighty_morphin:dragon_dagger", "mighty_morphin:blade_blaster",
  "mighty_morphin:power_blaster"}, { hidden = 1, leader = 1 }},
  {"green_no_shield", "Green", 100, 12, {"mighty_morphin:blade_blaster"}, { hidden = 1 }}
}

for i, v in ipairs(mmprrangers) do
  morphinggrid.register_ranger("mighty_morphin:"..v[1], {
    description = v[2].." Mighty Morphin Ranger",
    heal = v[3],
    use = v[4],
	color = v[1],
    weapons = v[6],
    ranger_groups = v[7],
    morpher = {
		name = "mighty_morphin:"..v[5].."_morpher",
		inventory_image = v[5].."_morpher.png",
		description = mighty_morphin.upper_first_char(v[5], true).." Morpher",
		griditems = { "mighty_morphin:"..v[5].."_powercoin" },
		prevents_respawn = true,
		grid_doc = {
			description = "Morphs a player into the Mighty Morphin "..v[2].." Ranger."
		},
		morpher_slots = {
			amount = 1,
			load_input = function(itemstack)
				return true, {ItemStack("mighty_morphin:"..v[5].."_powercoin")}
			end,
			output = function(itemstack, slots)
				if slots[1]:get_name() == "" then
					return true, ItemStack("mighty_morphin:empty_morpher")
				end
				return false, itemstack
			end,
			allow_put = function()
				return 0
			end,
			grid_doc = {
			inputs = {
					{ input = {} }
				}
			}
		},
		morph_func_override = function(user, itemstack)
			local ranger = morphinggrid.get_ranger("mighty_morphin:"..v[1])
			mighty_morphin.morph(user, ranger, "mighty_morphin:"..v[5].."_morpher", itemstack)
		end,
    },
  })
end

for i, v in ipairs(mmprrangers_shields) do
  morphinggrid.register_ranger("mighty_morphin:"..v[1], {
    description = v[2].." Mighty Morphin Ranger",
    heal = v[3],
    use = v[4],
    weapons = v[5],
    ranger_groups = v[6],
	create_rangerdata = false
  })
end
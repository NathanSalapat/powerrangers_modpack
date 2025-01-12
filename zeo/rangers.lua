dofile(minetest.get_modpath("morphinggrid") .. "/functions.lua")

morphinggrid.register_rangertype("zeo", {
  description = "Zeo",
  weapons = {"zeo:zeo_power_pod_sword",
              "zeo:zeo_laser_pistol",
              "zeo:zeo_i_power_disk",
              "zeo:zeo_ii_power_clubs",
              "zeo:zeo_iii_power_tonfas",
              "zeo:zeo_iv_power_hatchets",
              "zeo:zeo_v_power_sword",
              "zeo:advanced_zeo_laser_pistol"},
  grid_doc = {
    description = "Zeo is a team of rangers that uses the power of the Zeo Crystal to get their powers. The Zeo Crystal is "..
    "made of 5 sub crystals. Each crystal can be placed inside of a Right Zeonizer using morpher slots to get the "..
    "morpher desired. The only ranger that does not use a Zeo Sub Crystal is the Gold Zeo Ranger which uses the Gold "..
    "Zeo Staff. The Gold Zeo Staff is also the Gold Zeo Ranger's primary weapon when morphed."
  }
})

zeo.rangers = {
  {"pink", "Pink", 100, 5, {}, {"zeo:zeo_i_power_disk", "zeo:zeo_power_pod_sword", "zeo:zeo_laser_pistol", "zeo:advanced_zeo_laser_pistol"}},
  {"yellow", "Yellow", 100, 5, {}, {"zeo:zeo_ii_power_clubs", "zeo:zeo_power_pod_sword", "zeo:zeo_laser_pistol", "zeo:advanced_zeo_laser_pistol"}},
  {"blue", "Blue", 100, 5, {}, {"zeo:zeo_iii_power_tonfas", "zeo:zeo_power_pod_sword", "zeo:zeo_laser_pistol", "zeo:advanced_zeo_laser_pistol"}},
  {"green", "Green", 100, 5, {}, {"zeo:zeo_iv_power_hatchets", "zeo:zeo_power_pod_sword", "zeo:zeo_laser_pistol", "zeo:advanced_zeo_laser_pistol"}},
  {"red", "Red", 100, 5, { leader = 1 }, {"zeo:zeo_v_power_sword", "zeo:zeo_power_pod_sword", "zeo:zeo_laser_pistol", "zeo:advanced_zeo_laser_pistol"}}
}

for i, v in ipairs(zeo.rangers) do
  morphinggrid.register_ranger("zeo:"..v[1], {
    description = v[2].." Zeo Ranger",
    heal = v[3],
    use = v[4],
	color = v[1],
    weapons = v[6],
    ranger_groups = v[5],
    abilities = {
      strength = {
        full_punch_interval = 0.1,
        max_drop_level = 0,
        groupcaps = {
          crumbly = {times={[2]=3.00, [3]=0.70}, uses=0, maxlevel=1},
          snappy={times={[1]=1.90, [2]=0.90, [3]=0.30}, uses=1, maxlevel=3},
          cracky={times={[50]=0.10}, uses=1, maxlevel=50},
          oddly_breakable_by_hand = {times={[1]=3.50,[2]=2.00,[3]=0.70}, uses=0}
        },
        damage_groups = {fleshy=70},
      }
    },
    morpher = {
      name = "zeo:right_zeonizer_"..v[1],
      inventory_image = "zeo_zeonizer_right.png",
      description = "Right Zeonizer (Zeo Ranger "..i..")",
      griditems = { "zeo:zeo_crystal_"..i },
      prevents_respawn = true,
        morph_func_override = function(user, itemstack)
          local ranger = morphinggrid.get_ranger("zeo:"..v[1])
          zeo.morph(user, ranger)
        end,
      morpher_slots = {
        amount = 1,
        load_input = function(morpher)
          return true, {ItemStack("zeo:zeo_crystal_"..i)}
        end,
        output = function(morpher, slots)
          if slots[1]:get_name() == "" then
            return true, ItemStack("zeo:right_zeonizer")
          end
          return false, morpher
        end,
        allow_put = function(morpher, itemstack)
          return 0
        end,
        grid_doc = {
          inputs = {
            { input = {} },
          }
        }
      },
      grid_doc = {
        description = "Holds the Zeo Sub Crystal "..i..". A Left Zeonizer is required in a player's inventory to use for morphing." 
      }
    }
  })
end

morphinggrid.register_ranger("zeo:gold", {
    description = "Gold Zeo Ranger",
    heal = 100,
    use = 4,
	color = "gold",
    weapons = {},
    ranger_groups = {},
    abilities = {
      strength = {
        full_punch_interval = 0.1,
        max_drop_level = 0,
        groupcaps = {
          crumbly = {times={[2]=3.00, [3]=0.70}, uses=0, maxlevel=1},
          snappy={times={[1]=1.90, [2]=0.90, [3]=0.30}, uses=1, maxlevel=3},
          cracky={times={[50]=0.10}, uses=1, maxlevel=50},
          oddly_breakable_by_hand = {times={[1]=3.50,[2]=2.00,[3]=0.70}, uses=0}
        },
        damage_groups = {fleshy=70},
      }
    },
})
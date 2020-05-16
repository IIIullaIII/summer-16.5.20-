
local scalpello = {}


local S = minetest.get_translator("scalpello")


scalpello.ROTATE_FACE = 1
scalpello.ROTATE_AXIS = 2
scalpello.disallow = function(pos, node, user, mode, new_param2)
   return false
end
scalpello.rotate_simple = function(pos, node, user, mode, new_param2)
   if mode ~= scalpello.ROTATE_FACE then
      return false
   end
end


local function check_attached_node(pos, rotation)
   local d = minetest.wallmounted_to_dir(rotation)
   local p2 = vector.add(pos, d)
   local n = minetest.get_node(p2).name
   local def2 = minetest.registered_nodes[n]
   if def2 and not def2.walkable then
      return false
   end
   return true
end

scalpello.rotate = {}

local facedir_tbl = {
   [scalpello.ROTATE_FACE] = {
      [0] = 1, [1] = 2, [2] = 3, [3] = 0,
      [4] = 5, [5] = 6, [6] = 7, [7] = 4,
      [8] = 9, [9] = 10, [10] = 11, [11] = 8,
      [12] = 13, [13] = 14, [14] = 15, [15] = 12,
      [16] = 17, [17] = 18, [18] = 19, [19] = 16,
      [20] = 21, [21] = 22, [22] = 23, [23] = 20,
   },
   [scalpello.ROTATE_AXIS] = {
      [0] = 4, [1] = 4, [2] = 4, [3] = 4,
      [4] = 8, [5] = 8, [6] = 8, [7] = 8,
      [8] = 12, [9] = 12, [10] = 12, [11] = 12,
      [12] = 16, [13] = 16, [14] = 16, [15] = 16,
      [16] = 20, [17] = 20, [18] = 20, [19] = 20,
      [20] = 0, [21] = 0, [22] = 0, [23] = 0,
   },
}

scalpello.rotate.facedir = function(pos, node, mode)
   local rotation = node.param2 % 32 
   local other = node.param2 - rotation
   rotation = facedir_tbl[mode][rotation] or 0
   return rotation + other
end

scalpello.rotate.colorfacedir = scalpello.rotate.facedir

local wallmounted_tbl = {
   [scalpello.ROTATE_FACE] = {[2] = 5, [3] = 4, [4] = 2, [5] = 3, [1] = 0, [0] = 1},
   [scalpello.ROTATE_AXIS] = {[2] = 5, [3] = 4, [4] = 2, [5] = 1, [1] = 0, [0] = 3}
}

scalpello.rotate.wallmounted = function(pos, node, mode)
   local rotation = node.param2 % 8
   local other = node.param2 - rotation
   rotation = wallmounted_tbl[mode][rotation] or 0
   if minetest.get_item_group(node.name, "attached_node") ~= 0 then
      
      for i = 1, 5 do
         if not check_attached_node(pos, rotation) then
            rotation = wallmounted_tbl[mode][rotation] or 0
         else
            break
         end
      end
   end
   return rotation + other
end

scalpello.rotate.colorwallmounted = scalpello.rotate.wallmounted


scalpello.handler = function(itemstack, user, pointed_thing, mode, uses)
   if pointed_thing.type ~= "node" then
      return
   end

   local pos = pointed_thing.under
   local player_name = user and user:get_player_name() or ""

   if minetest.is_protected(pos, player_name) then
      minetest.record_protection_violation(pos, player_name)
      return
   end

   local node = minetest.get_node(pos)
   local ndef = minetest.registered_nodes[node.name]
   if not ndef then
      return itemstack
   end

   local fn = scalpello.rotate[ndef.paramtype2]
   if not fn and not ndef.on_rotate then
      return itemstack
   end

   local should_rotate = true
   local new_param2
   if fn then
      new_param2 = fn(pos, node, mode)
   else
      new_param2 = node.param2
   end

  
   if ndef.on_rotate then
 
      local result = ndef.on_rotate(vector.new(pos),
            {name = node.name, param1 = node.param1, param2 = node.param2},
            user, mode, new_param2)
      if result == false then
         return itemstack
      elseif result == true then
         should_rotate = false
      end
   elseif ndef.on_rotate == false then
      return itemstack
   elseif ndef.can_dig and not ndef.can_dig(pos, user) then
      return itemstack
   end

   if should_rotate and new_param2 ~= node.param2 then
      node.param2 = new_param2
      minetest.swap_node(pos, node)
      minetest.check_for_falling(pos)
   end

   if not (creative and creative.is_enabled_for and
         creative.is_enabled_for(player_name)) then
      itemstack:add_wear(65535 / ((uses or 200) - 1))
   end

   return itemstack
end


local nodi_list = {
   
   { "granite", "angstair", "angstair2","stair","slab"},
   { "graniteA", "angstairA", "angstairA2","stairA","slabA"},
    { "graniteR", "angstairR", "angstairR2","stairR","slabR"},
   { "graniteP", "angstairP", "angstairP2","stairP","slabP"}
   }

for i in ipairs(nodi_list) do
   local ndesc = nodi_list[i][1]
   local ang = nodi_list[i][2]
   local angg = nodi_list[i][3]
   local sta = nodi_list[i][4]
   local sla = nodi_list[i][5]
   


minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
   
   if puncher:get_wielded_item():get_name() == "summer:scalpello"
   and node.name =="summer:"..ndesc..""  and puncher:get_player_control().sneak then
      minetest.remove_node(pos)
          node.name = "summer:"..sta..""
           minetest.set_node(pos, node)
          
           minetest.sound_play("summer_n_swap", {
   to_player = "",
   gain = 2.0,})
 
   else 
       if puncher:get_wielded_item():get_name() == "summer:scalpello"
  then
     minetest.sound_play("summer_n_swap_1", {
   to_player = "",
   gain = 2.0,})
   

      scalpello.handler(itemstack, user, pointed_thing, scalpello.ROTATE_FACE, 200)
      return itemstack
      end
      end    
   
      end)
minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
   
   if puncher:get_wielded_item():get_name() == "summer:scalpello"
   and node.name =="summer:"..sta.."" and puncher:get_player_control().sneak then
      minetest.remove_node(pos)
          node.name = "summer:"..angg..""
           minetest.set_node(pos, node)
          
           minetest.sound_play("summer_n_swap", {
   to_player = "",
   gain = 2.0,})
   else if puncher:get_wielded_item():get_name() == "summer:scalpello"
   then
  minetest.sound_play("summer_n_swap_1", {
   to_player = "",
   gain = 2.0,})    
  
     scalpello.handler(itemstack, user, pointed_thing, scalpello.ROTATE_FACE, 200)
      return itemstack
end 
 end 

      end)
minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
   
   if puncher:get_wielded_item():get_name() == "summer:scalpello"
   and node.name =="summer:"..angg.."" and puncher:get_player_control().sneak then
      minetest.remove_node(pos)
          node.name = "summer:"..ang..""
           minetest.set_node(pos, node)
          
           minetest.sound_play("summer_n_swap", {
   to_player = "",
   gain = 2.0,})
   else  
       if puncher:get_wielded_item():get_name() == "summer:scalpello"
    then
    minetest.sound_play("summer_n_swap_1", {
   to_player = "",
   gain = 2.0,})         
    
     scalpello.handler(itemstack, user, pointed_thing, scalpello.ROTATE_FACE, 200)
      return itemstack
end
  
 end 

end)
minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
   
   if puncher:get_wielded_item():get_name() == "summer:scalpello"
   and node.name =="summer:"..ang.."" and puncher:get_player_control().sneak then
      minetest.remove_node(pos)
          node.name = "summer:"..sla..""
           minetest.set_node(pos, node)
          
           minetest.sound_play("summer_n_swap", {
   to_player = "",
   gain = 2.0,})
   else if puncher:get_wielded_item():get_name() == "summer:scalpello"
    then
    minetest.sound_play("summer_n_swap_1", {
   to_player = "",
   gain = 2.0,})         
     
     scalpello.handler(itemstack, user, pointed_thing, scalpello.ROTATE_FACE, 200)
      return itemstack
end
 end 


end)
minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
   
   if puncher:get_wielded_item():get_name() == "summer:scalpello"
   and node.name =="summer:"..sla.."" and puncher:get_player_control().sneak then
      minetest.remove_node(pos)
          node.name = "summer:"..ndesc..""
           minetest.set_node(pos, node)
          
           minetest.sound_play("summer_n_swap", {
   to_player = "",
   gain = 2.0,})
     else  if puncher:get_wielded_item():get_name() == "summer:scalpello"
   then
  minetest.sound_play("summer_n_swap_1", {
   to_player = "",
   gain = 2.0,})        
     
     scalpello.handler(itemstack, user, pointed_thing, scalpello.ROTATE_FACE, 200)
      return itemstack
end
  
 end 

end)
end



minetest.register_tool("summer:scalpello", {
   description = "Scalpello",
   inventory_image = "scalpello.png",
   on_place = function(itemstack, user, pointed_thing)
      minetest.sound_play("summer_n_swap_2", {   
         to_player = user:get_player_name() ,
         gain = 2.0
      })
      scalpello.handler(itemstack, user, pointed_thing, scalpello.ROTATE_AXIS, 200)
      return itemstack
   end,
 


})
minetest.register_craft({
   output = "summer:scalpello",
   recipe = {
       {"default:steel_ingot"},
      {"default:steel_ingot"},
      {"group:stick"}
   }
})


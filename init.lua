-- Автор: Василь Онуфрійчук
-- Ліцензія: GNU GPL v3

local RANGE = tonumber(minetest.settings:get("custom_nametag_range")) or 8
local UPDATE = tonumber(minetest.settings:get("custom_nametag_update")) or 1.5
local NAME_HEIGHT = tonumber(minetest.settings:get("custom_nametag_height")) or 1.2

-- 🔴 ховаємо стандартні ніки
minetest.register_on_joinplayer(function(player)
	player:set_nametag_attributes({
		text = "",
		color = {a = 0, r = 0, g = 0, b = 0},
		distance = 0
	})
end)

-- 🧠 entity
minetest.register_entity("custom_nametags:name_tag", {
	initial_properties = {
		visual = "upright_sprite",
		textures = {"blank.png"},
		pointable = false,
		static_save = false,
		visual_size = {x = 0, y = 0},
	},

	on_activate = function(self)
		self.object:set_armor_groups({immortal = 1})
	end,
})

-- 📦 storage
local tags = {}

-- 📦 create tag
local function create_tag(player)
	local obj = minetest.add_entity(player:get_pos(), "custom_nametags:name_tag")
	if not obj then return nil end

	obj:set_properties({
		nametag = player:get_player_name(),
		nametag_color = {a = 255, r = 255, g = 255, b = 255}
	})

	return obj
end

-- 🧹 глобальна чистка (ВАЖЛИВО)
local function cleanup()
	for viewer, list in pairs(tags) do
		for target, obj in pairs(list) do
			if not obj or not obj:get_luaentity() then
				list[target] = nil
			end
		end
	end
end

-- 🔵 main loop
local function update()
	local players = minetest.get_connected_players()

	-- 🧹 спочатку чистимо “завислі” entity
	cleanup()

	for _, viewer in ipairs(players) do
		local vpos = viewer:get_pos()
		local vname = viewer:get_player_name()

		if not tags[vname] then
			tags[vname] = {}
		end

		for _, target in ipairs(players) do
			if target ~= viewer then
				local tname = target:get_player_name()
				local dist = vector.distance(vpos, target:get_pos())

				if dist <= RANGE then

					-- ✔ створюємо тільки якщо нема або зламалась
					if not tags[vname][tname] or not tags[vname][tname]:get_luaentity() then
						tags[vname][tname] = create_tag(target)
					end

					local obj = tags[vname][tname]
					if obj then
						local pos = target:get_pos()
						obj:set_pos({
							x = pos.x,
							y = pos.y + NAME_HEIGHT,
							z = pos.z
						})
					end

				else
					local obj = tags[vname][tname]
					if obj then obj:remove() end
					tags[vname][tname] = nil
				end
			end
		end
	end

	minetest.after(UPDATE, update)
end

minetest.after(1, update)

-- 🧹 cleanup при виході
minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()

	for _, list in pairs(tags) do
		if list[name] then
			if list[name] then
				list[name]:remove()
			end
			list[name] = nil
		end
	end

	tags[name] = nil
end)

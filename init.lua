--[[ TODO:
	- Proper black/white ownership by respective player.
	- Proper turn by turn handling;
	- Proper piece replacement (ie: if piece A eats piece B, piece B is properly replaced without getting a stack under the cursor);
	- If a pawn reaches row A or row H -> becomes a queen;
	- If one of kings is defeat -> the game stops;
	- Actions recording;
	- Counter per player.
--]]



realchess = {}

function realchess.fs(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local slots = "listcolors[#00000000;#00000000;#00000000;#30434C;#FFF]"
	
	local rows = {
		{'A', 0}, {'B', 1}, {'C', 2}, {'D', 3}, {'E', 4}, {'F', 5}, {'G', 6}, {'H', 7}
	}
	local formspec = ""
	for _, n in pairs(rows) do
		local letter = n[1]
		local number = n[2]
		inv:set_size(letter, 8)
		formspec = formspec.."list[context;"..letter..";0,"..number..";8,1;false]"
	end
	
	meta:set_string("formspec", "size[8,8.6;]bgcolor[#080808BB;true]background[0,0;8,8;chess_bg.png]button[3.2,7.6;2,2;new;New game]"..formspec..slots)
	meta:set_string("infotext", "Chess Board")
	meta:set_string("playerOne", "")
	meta:set_string("playerTwo", "")
	meta:set_string("lastMove", "")

	inv:set_list('A', {"realchess:tower_black_1 1", "realchess:horse_black_1 1", 
			"realchess:fool_black_1 1", "realchess:king_black_1 1", 
			"realchess:queen_black_1 1", "realchess:fool_black_2 1",
			"realchess:horse_black_2 1", "realchess:tower_black_2 1"})
			
	inv:set_list('H', {"realchess:tower_white_1 1", "realchess:horse_white_1 1", 
			"realchess:fool_white_1 1", "realchess:queen_white_1 1", 
			"realchess:king_white_1 1", "realchess:fool_white_2 1",
			"realchess:horse_white_2 1", "realchess:tower_white_2 1"})

	inv:set_list("C", {})
	inv:set_list("D", {})
	inv:set_list("E", {})
	inv:set_list("F", {})
	
	local bpawns, wpawns = {}, {}
	for i = 1, 8 do
		bpawns[#bpawns+1] = "realchess:pawn_black_"..i.." 1"
		wpawns[#wpawns+1] = "realchess:pawn_white_"..i.." 1"
		inv:set_list('B', bpawns)
		inv:set_list('G', wpawns)
	end
end

function realchess.move(pos, from_list, from_index, to_list, to_index, count, player)
	local inv = minetest.get_meta(pos):get_inventory()
	local meta = minetest.get_meta(pos)
	local pieceFrom = inv:get_stack(from_list, from_index):get_name()
	local pieceTo = inv:get_stack(to_list, to_index):get_name()
	local pname = player:get_player_name()

	--print("Piece From: "..pieceFrom.." | from_list: "..from_list.." | from_index: "..from_index.." | Converted 'from_list':"..string.byte(from_list))
	--print("Piece To: "..pieceTo.." | to_list: "..to_list.." | to_index: "..to_index.." | Converted 'to_list':"..string.byte(to_list))

	
	--[[ Bugginess
	-- Turn by turn
	if pieceFrom:find("white") and (meta:get_string("lastMove") == "" or
			meta:get_string("lastMove") == "black") then
		meta:set_string("lastMove", "white")
		meta:set_string("playerOne", pname) -- it's shit
		return 1
	elseif pieceFrom:find("white") and meta:get_string("lastMove") == "white" then
		minetest.chat_send_player(pname, "It's not your turn, wait your opponent to play.")
		return 0
	elseif pieceFrom:find("black") and (meta:get_string("lastMove") == "" or
			meta:get_string("lastMove") == "white") then
		meta:set_string("lastMove", "black")
		meta:set_string("playerTwo", pname) -- it's shit
		return 1
	elseif pieceFrom:find("black") and meta:get_string("lastMove") == "black" then
		minetest.chat_send_player(pname, "It's not your turn, wait your opponent to play.")
		return 0
	end
	-- ]]

	-- Don't replace pieces of same color
	if (pieceFrom:find("white") and pieceTo:find("white")) or 
		(pieceFrom:find("black") and pieceTo:find("black")) then
		return 0
	end

	-- DETERMINISTIC MOVING
	
	-- PAWNS
	if pieceFrom:find("pawn_white") then
		if from_index == to_index and
			inv:get_stack(string.char(string.byte(from_list)-1), from_index):get_name() == "" then
				if string.byte(to_list) == string.byte(from_list) - 1 then
					return 1
				elseif from_list == 'G' and
					string.byte(to_list) == string.byte(from_list) - 2 then
					return 1
				end
		elseif string.byte(from_list) > string.byte(to_list) and
			(from_index ~= to_index and pieceTo:find("black")) then
			return 1
		end
	elseif pieceFrom:find("pawn_black") then
		if from_index == to_index and
			inv:get_stack(string.char(string.byte(from_list)+1), from_index):get_name() == "" then
				if string.byte(to_list) == string.byte(from_list) + 1 then
					return 1
				elseif from_list == 'B' and
					string.byte(to_list) == string.byte(from_list) + 2 then
					return 1
				end
		elseif string.byte(from_list) < string.byte(to_list) and
			(from_index ~= to_index and pieceTo:find("white")) then
			return 1
		end
	end


	-- TOWERS
	if pieceFrom:find("tower") then
		for i = 1, 7 do
			if from_index == to_index and (string.byte(to_list) == string.byte(from_list) - i or
				string.byte(to_list) == string.byte(from_list) + i) then
				return 1
			elseif string.byte(to_list) == string.byte(from_list) and
				from_index ~= to_index then
				return 1
			end
		end
	end


	-- HORSES
	local horse_dirs = {
		{-2, -1}, {-2, 1}, {2, 1}, {2, -1}, -- Moves type 1
		{-1, 2}, {-1, -2}, {1, -2}, {1, 2} -- Moves type 2
	}

	if pieceFrom:find("horse") then
		for _, d in pairs(horse_dirs) do
			if string.byte(to_list) == string.byte(from_list) + d[1] and
				(to_index == from_index + d[2]) then
				return 1
			end
		end
	end


	-- FOOLS
	if pieceFrom:find("fool") then
		for i = 1, 7 do
			if (to_index == from_index + i or to_index == from_index - i) and
				(string.byte(to_list) == string.byte(from_list) - i or
				string.byte(to_list) == string.byte(from_list) + i) then
				return 1
			end
		end
	end


	-- QUEENS
	if pieceFrom:find("queen") then
		for i = 1, 7 do
			if from_index == to_index and (string.byte(to_list) == string.byte(from_list) - i or
				string.byte(to_list) == string.byte(from_list) + i) then
				return 1
			elseif string.byte(to_list) == string.byte(from_list) and
				from_index ~= to_index then
				return 1
			elseif (to_index == from_index + i or to_index == from_index - i) and
				(string.byte(to_list) == string.byte(from_list) - i or
				string.byte(to_list) == string.byte(from_list) + i) then
				return 1
			end
		end
	end


	-- KINGS
	if pieceFrom:find("king") then
		if from_index == to_index and (string.byte(to_list) == string.byte(from_list) - 1 or
			string.byte(to_list) == string.byte(from_list) + 1) then
			return 1
		elseif string.byte(to_list) == string.byte(from_list) and
			from_index ~= to_index then
			return 1
		elseif (to_index == from_index + 1 or to_index == from_index - 1) and
			(string.byte(to_list) == string.byte(from_list) - 1 or
			string.byte(to_list) == string.byte(from_list) + 1) then
			return 1
		end
	end

	return 0
end
	
function realchess.fields(pos, formname, fields, sender)
	local pname = sender:get_player_name()
	local meta = minetest.get_meta(pos)

	if fields.quit then return end
	-- If someone's playing, nobody except the players can reset the game
	if fields.new and (meta:get_string("playerOne") == pname or
			meta:get_string("playerTwo") == pname) then
		realchess.fs(pos)
	else
		minetest.chat_send_player(pname, "You can't reset the game unless if you're playing it.")
	end
end

function realchess.dig(pos, player)
	local meta = minetest.get_meta(pos)
	local pname = player:get_player_name()

	-- If someone's playing, the chess can't be dug
	if meta:get_string("playerOne") ~= "" or meta:get_string("playerTwo") ~= "" then
		minetest.chat_send_player(pname, "You can't dug the chess, a game has been started.")
		return false
	end
	return true
end

minetest.register_node("realchess:chessboard", {
	description = "Chess Board",
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	inventory_image = "chessboard_top.png",
	wield_image = "chessboard_top.png",
	tiles = {"chessboard_top.png", "chessboard_top.png",
		"chessboard_sides.png", "chessboard_sides.png",
		"chessboard_top.png", "chessboard_top.png"},
	groups = {choppy=3, fammable=3},
	sounds = default.node_sound_wood_defaults(),
	node_box = {type = "fixed", fixed = {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5}},
	can_dig = realchess.dig,
	on_construct = realchess.fs,
	on_receive_fields = realchess.fields,
	allow_metadata_inventory_move = realchess.move,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_stack(from_list, from_index, '')
	end
})

local pieces = {
	{name = "pawn", count = 8},
	{name = "tower", count = 2},
	{name = "horse", count = 2},
	{name = "fool", count = 2},
	{name = "queen", count = 1},
	{name = "king", count = 1}
}
local colors = {"black", "white"}

for _, p in pairs(pieces) do
for _, c in pairs(colors) do
for i = 1, p.count do
	minetest.register_craftitem("realchess:"..p.name.."_"..c.."_"..i, {
		description = c:gsub("^%l", string.upper).." "..p.name:gsub("^%l", string.upper),
		inventory_image = p.name.."_"..c..".png",
		stack_max = 1,
		groups = {not_in_creative_inventory=1}
	})
end
end
end

minetest.register_craft({ 
	output = "realchess:chessboard",
	recipe = {
		{"dye:black", "dye:white", "dye:black"},
		{"stairs:slab_wood", "stairs:slab_wood", "stairs:slab_wood"}
	} 
})


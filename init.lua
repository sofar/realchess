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

	inv:set_list('A', {"realchess:tower_black 1", "realchess:horse_black 1", 
			"realchess:fool_black 1", "realchess:king_black 1", 
			"realchess:queen_black 1", "realchess:fool_black 1",
			"realchess:horse_black 1", "realchess:tower_black 1"})
			
	inv:set_list('H', {"realchess:tower_white 1", "realchess:horse_white 1", 
			"realchess:fool_white 1", "realchess:queen_white 1", 
			"realchess:king_white 1", "realchess:fool_white 1",
			"realchess:horse_white 1", "realchess:tower_white 1"})

	inv:set_list("C", {})
	inv:set_list("D", {})
	inv:set_list("E", {})
	inv:set_list("F", {})
	
	local bpawns, wpawns = {}, {}
	for i = 0, 7 do
		bpawns[#bpawns+1] = "realchess:pawn_black 1"
		wpawns[#wpawns+1] = "realchess:pawn_white 1"
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

	--print("Piece: "..piece_a.." | from_list: "..from_list.." | from_index: "..from_index.." | Converted 'from_list':"..string.byte(from_list))
	--print("Piece: "..piece_b.." | to_list: "..to_list.." | to_index: "..to_index.." | Converted 'to_list':"..string.byte(to_list))


	-- Turn by turn
	if pieceFrom:find("white") and (meta:get_string("lastMove") == "" or
			meta:get_string("lastMove") == "black") then
		if meta:get_string("playerOne") == "" and
				meta:get_string("playerTwo") == "" then
			meta:set_string("playerOne", pname)
			meta:set_string("lastMove", "white")
			return 1
		elseif meta:get_string("playerOne") ~= "" and
				meta:get_string("playerTwo") == "" then
			meta:set_string("playerTwo", pname)
			meta:set_string("lastMove", "white")
			return 1
		elseif pname ~= meta:get_string("playerOne") or
				pname ~= meta:get_string("playerTwo") then
			minetest.chat_send_player(pname, "You can't move the pieces of your opponent !")
			return 0
		end
		return 0
	elseif pieceFrom:find("white") and meta:get_string("lastMove") == "white" then
		minetest.chat_send_player(pname, "It's not your turn, wait your opponent to play.")
		return 0
	elseif pieceFrom:find("black") and (meta:get_string("lastMove") == "" or
			meta:get_string("lastMove") == "white") then
		if meta:get_string("playerOne") == "" and
				meta:get_string("playerTwo") == "" then
			meta:set_string("playerOne", pname)
			meta:set_string("lastMove", "black")
			return 1
		elseif meta:get_string("playerOne") ~= "" and
				meta:get_string("playerTwo") == "" then
			meta:set_string("playerTwo", pname)
			meta:set_string("lastMove", "black")
			return 1
		elseif pname ~= meta:get_string("playerOne") or
				pname ~= meta:get_string("playerTwo") then
			minetest.chat_send_player(pname, "You can't move the pieces of your opponent !")
			return 0
		end
		return 0
	elseif pieceFrom:find("black") and meta:get_string("lastMove") == "black" then
		minetest.chat_send_player(pname, "It's not your turn, wait your opponent to play.")
		return 0
	end


	-- Don't replace pieces of same color
	if (piece_a:find("white") and piece_b:find("white")) or 
		(piece_a:find("black") and piece_b:find("black")) then
		return 0
	end


	-- PAWNS
	if pieceFrom:find("pawn_white") then
		if from_index == to_index then
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
		if from_index == to_index then
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
		return 0
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
		return 0
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
		return 0
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
		return 0
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
		return 0
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
		return 0
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
		print(meta:get_string("playerOne"))
		print(meta:get_string("playerTwo"))
		realchess.fs(pos)
	else
		print(meta:get_string("playerOne"))
		print(meta:get_string("playerTwo"))
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
	tiles = {"chessboard_top.png", "chessboard_top.png",
		"chessboard_sides.png", "chessboard_sides.png",
		"chessboard_top.png", "chessboard_top.png"},
	groups = {choppy=3, fammable=3},
	sounds = default.node_sound_wood_defaults(),
	node_box = {type = "fixed", fixed = {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5}},
	can_dig = realchess.dig,
	on_construct = realchess.fs,
	on_receive_fields = realchess.fields,
	allow_metadata_inventory_move = realchess.move
})

local pieces = {"pawn", "tower", "horse", "fool", "queen", "king"}
local colors = {"black", "white"}

for _, p in pairs(pieces) do
for _, c in pairs(colors) do
	minetest.register_craftitem("realchess:"..p.."_"..c, {
		description = c:gsub("^%l", string.upper).." "..p:gsub("^%l", string.upper),
		inventory_image = p.."_"..c..".png",
		stack_max = 1,
		groups = {not_in_creative_inventory=1}
	})
end
end

minetest.register_craft({ 
	output = "realchess:chessboard",
	recipe = {
		{"dye:black", "dye:white", "dye:black"},
		{"stairs:slab_wood", "stairs:slab_wood", "stairs:slab_wood"}
	} 
})


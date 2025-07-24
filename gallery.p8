pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
view_enemies = peek(0x8000) == 1
enemy_index = 1
enemy_card_index = 1
enemy_card_y_offsets = {}
enemy_card_x_offset=0
card_y_offsets = {}  -- Table to store y offset for each card
cursor_x = 1
cursor_y = 1
camera_y = 0
camera_ty = 0
desc_y = 128
function rpal()
	poke(0x5f2e ,1)
	pal()
pal({[0]=0,128,2,132,
									133,141,6,7,
										8,139,129,130,
										12,13,137,15},1)
										palt(14,true)
										palt(0,false)
end
rpal()
function _init()
	cartdata("demons_of_the_great_beyond")
	palt(14,true)
	palt(0,false)
	music_disabled=peek(0x5e00+73)==1
	if not music_disabled then
		music(30, 4000)
	end
	menuitem(3, "toggle music", function()
		music_disabled = not music_disabled
		poke(0x5e00+73, music_disabled and 1 or 0)
		if music_disabled then
			music(-1, 500)
		else
			music(30, 2000)
		end
	end)
end
function draw_sprite(s,x,y)
	spr(s+(time()%1>0.5 and 1 or 0),x+4,y+4,1,1)
end
function draw_deinterlaced(x,y,sx,sy,primary, hidden)
    if not hidden then
		if primary then
			pal(split"5,5,8,8,8,7,7,7,8,8,8,14,14,14,8") -- Only 9 colors should be used, the rest are set to 8 (bright red)    
			palt(12,true)
			palt(13,true)
			palt(14,true)
		else
			pal(split"7,14,8,8,8,5,7,14,8,8,8,5,7,14,8")-- Only 9 colors should be used, the rest are set to 8 (bright red)
			palt(2,true)
			palt(8,true)
			palt(14,true)
		end  
		palt(0,false)
		pal(0,5)
	else
		pal(split"0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0") -- Only 9 colors should be used, the rest are set to 8 (bright red)    
			
		if primary then
			palt(12,true)
			palt(13,true)
			palt(14,true)
		else
			palt(2,true)
			palt(8,true)
			palt(14,true)
		end  
		palt(0,false)
		pal(0,0)
	end

	sspr(sx,sy,32,32,x,y)
	rpal()
end
function draw_enemy(e,x,y, hidden)
	draw_deinterlaced(x,y,e.facex,e.facey,e.facealt!=1, hidden)
end
function draw_card(hc,actor)
	local c,x,y=hc.c,hc.x,hc.y
	if hc.ability_at then
		local t= time()-hc.ability_at
		if t<.5 then
			y+=(t-.5)*t*(100)
		end
	end
	if c=="endturn" or c=="skip" then
		spr(66,x,y,2,2)
		spr(96,x+4,y+4)
		return
	else if c=="remove card" then
		spr(66,x,y,2,2)
		spr(97,x+4,y+4)
		return
	end
	end
	pal(7,7)
	pal(8,hc.hidden and 0 or types[c.type])
	if hc.hidden then
		pal(4,4)
		pal(7,6)
	else
		pal(4,0)
		pal(7,7)
	end
	spr(64,x,y,2,2)
	if hc.hidden then
		pal(8,0)
		pal(7,0)
		palt(0,true)
	else
		pal(7,7)
		pal(8,0)
		palt(0,false)
	end
	draw_sprite(c.s,x,y)
	
	pal(7,7)
	pal(8,8)
end


function draw_summary(c_or_c_wrapper,y,full)
	local c=c_or_c_wrapper.c or c_or_c_wrapper
	local rc= c_or_c_wrapper.hp and c_or_c_wrapper or nil
	local str = c.name
	rectfill(64-2*#str,y,64+2*#str,y+4,0)
	print(str,64-2*#str,y,7)
	y+=7
	local str = c.type
	rectfill(64-2*#str,y,64+2*#str,y+4,0)
	print(str,64-2*#str,y,types[c.type])
	y+=7
	rectfill(64-2*#str,y,64+2*#str,y+4,0)
	if rc and rc.hp != c.def then
		str = c.cost.."✽, "..c.atk.."/"
		local x = print(str,64-2*#str,y,7)
		print(rc.hp,x,y,8)
	else
		str = c.cost.."✽, "..c.atk.."/"..c.def..""
		print(str,64-2*#str,y,7)
	end
	y+=7

	if(full)then
		for str in all(type_desc[c.type]) do
			rectfill(64-2*#str,y,64+2*#str,y+4,0)
			print(str,64-2*#str,y,types[c.type])
			y+=7
		end
	end	
	if c.desc then 
		str = c.desc
		local x = 64-2*#str
		local w = full and 30 or 12
		clip(64-w*3,0,w*2*3,128)
		if #str > w then
			preview_changed_at=preview_changed_at or 0
			local t=(time()-preview_changed_at)*6
			t %= (#str - w + 8)
			x=(full and 16 or 40)-t*4
		end
		rectfill(0,y,128,y+4,0)
		print(str,x,y,7)
		clip()
		y+=7
	end
	if c.name=="twin" then
		str="in honor of pentagon"
		rectfill(64-2*#str,y,64+2*#str,y+4,0)
		print(str,64-2*#str,y,14)
		y+=7
	end
end
-- parens-8 v3
-- a lisp interpreter by three rodents

function parens8(code)
	_pstr, _ppos = "id " .. code .. ")", 0
	return compile({parse()}, function(name) return name, 1 end){{_ENV}}
end

function id(...) return ... end

function consume(matches, inv)
	local start = _ppos
	while (function()
		for m in all(matches) do
			if (_pstr[_ppos] == m) return true
		end
	end)() == inv do _ppos += 1 end
	return sub(_pstr, start, _ppos - 1)
end

function parse(off)
	_ppos += off or 1
	consume(' \n\t', true)
	local c = _pstr[_ppos]
	-- if (c == ';') consume'\n' return parse()  -- comments support
	if (c == '(') return {parse()}, parse()
	if (c == ')') return
	if (c == '"' or c == "'") _ppos += 1 return {"quote", consume(c)}, parse()
	local token = consume' \n\t()\'"'
	return tonum(token) or token, parse(0)
end

builtin = {}

function compile_n(lookup, exp, ...)
	if (exp) return compile(exp, lookup), compile_n(lookup, ...)
end

function compile(exp, lookup)
	if type(exp) == "string" then
		local fields, variadic = split(exp, "."), exp == "..."
		if (fields[2] and not variadic) return fieldview(lookup, deli(fields, 1), fields)
		local idx, where = lookup(exp)
		if variadic then
			return where
				and function(frame) return unpack(frame[1][where], idx) end
				or function(frame) return unpack(frame, idx) end
		end
		return where
			and function(frame) return frame[1][where][idx] end
			or function(frame) return frame[idx] end
	end
	if (type(exp) == "number") return function() return exp end

	local op = deli(exp, 1)
	if (builtin[op]) return builtin[op](lookup, unpack(exp))

	local function ret(s1, ...)
		local s2 = ... and ret(...)
		return s2 and function(frame)
			return s1(frame), s2(frame)
		end or s1
	end
	local fun, args =
		compile(op, lookup), ret(compile_n(lookup, unpack(exp)))
		return args and function(frame)
			local f = fun(frame)
			if(f) return f(args(frame))
			assert(false, op .. " was nil")
		end or function(frame)
			local f = fun(frame)
			if(f) return f()
			assert(false, op .. " was nil")
		end
	
end

function builtin:quote(exp2) return function() return exp2 end end

function builtin:fn(exp1, exp2)
	local locals, captures, key, close =
		parens8[[(quote ()) (quote ()) (quote ())]]
	for i,v in inext, exp1 do locals[v] = i end
	local body = compile(exp2, function(name)
		local idx = locals[name]
		if (idx) return idx + 1, false
		local idx, where = self(name)
		if where then captures[where] = true
		else close = true end
		return idx, where or key
	end)
	return close
		and function(frame)
			local upvals = {[key] = frame}
			for where in next, captures do
				upvals[where] = frame[1][where]
			end
			return function(...)
				return body{upvals, ...}
			end
		end
		or function(frame)
			return function(...)
				return body{frame[1], ...}
			end
		end
end

parens8[[
(fn (closure) (rawset builtin "when" (fn (lookup e1 e2 e3)
	(closure (compile_n lookup e1 e2 e3))
)))
]](function(a1, a2, a3) return
	function(frame)
		if (a1(frame)) return a2(frame)
		if (a3) return a3(frame)
	end
end)

parens8[[
(fn (closures) (rawset builtin "set" (fn (lookup exp1 exp2)
	((fn (compiled fields) ((fn (head tail) (when tail
		(select 3 (closures compiled tail (fieldview lookup head fields)))
		((fn (idx where) (select (when where 1 2)
			(closures compiled idx where)
		)) (lookup head))
	)) (deli fields 1) (deli fields))) (compile exp2 lookup) (split exp1 "."))
)))
]](function(compiled, idx, where) return
	function(frame) frame[1][where][idx] = compiled(frame) end,
	function(frame) frame[idx] = compiled(frame) end,
	function(frame) where(frame)[idx] = compiled(frame) end
end)

parens8[[
(fn (closure) (set fieldview (fn (lookup tab fields view) (select -1
	(set view (fn (step i field) (when field (view
		(closure step field)
		(inext fields i)
	) step)))
	(view (compile tab lookup) (inext fields))
))))
]](function(step, field)
	return function(frame)
		return step(frame)[field]
	end
end)
-- slightly simplified: {[0] = 1} works, {[foo] = 1} doesn't
-- (table (foo 1) (0 2) 3 4 5 6)
-- (table (x 1) (y 2))
function builtin.table(...)
	return parens8[[
	(fn (exp) ((fn (closures lookup construct) (select -1
		(set construct (fn (i elem) (when elem
			((fn (step) (when (count elem)
				(select 1 (closures
					step (compile (rawget elem 2) lookup) (rawget elem 1)))
				(select 2 (closures step (compile elem lookup)))
			)) (construct (inext exp i)))
			id
		)))
		(select 3 (closures (construct (inext exp))))
	)) (deli exp 1) (deli exp 1)))
	]]{function(step, elem, key) return
		function(res, frame)
			res[key] = elem(frame)
			return step(res, frame)
		end,
		function(res, frame)
			add(res, elem(frame))
			return step(res, frame)
		end,
		function(frame)
			return (step({}, frame))
		end
	end, ...}
end
function repack(f) return function(...) return f{...} end end

parens8[[
(fn (unroll) (rawset builtin "seq" (repack
    (fn (args) ((fn (lookup e1 e2 e3) 
        ((fn (s1 s2) (select (mid 3 (rawlen args)) s1 (unroll s1 s2 (when e3
            ((rawget builtin "seq") lookup (unpack args 3)))))
        ) (compile_n lookup e1 e2))
    ) (deli args 1) (unpack args)))
) ((fn (func) (rawset builtin "fn" (repack (fn (args)
    (func (deli args 1) (deli args 1) (pack "seq" (unpack args)))
)))) (rawget builtin "fn")) ))
]](function(s1, s2, s3)
    return function(frame)
        s1(frame)
        return s2(frame)
    end, function(frame)
        s1(frame)
        s2(frame)
        return s3(frame)
    end
end)

-- 56 tokens, inlines up to 4 before looping
-- function builtin.seq(...)
-- 	return parens8[[
-- 		(fn (exp) ((fn (unroll lookup e1 e2 e3 e4) 
-- 			((fn (s1 s2 s3) (select (mid 4 (rawlen exp))
-- 				s1 (unroll s1 s2 s3 (when e4
-- 					((rawget builtin "seq") lookup (unpack exp 4)))))
-- 			) (compile_n lookup e1 e2 e3))
-- 		) (deli exp 1) (deli exp 1) (unpack exp)))
-- 	]]{function(s1, s2, s3, s4)
-- 		return function(frame)
-- 			s1(frame)
-- 			return s2(frame)
-- 		end, function(frame)
-- 			s1(frame)
-- 			s2(frame)
-- 			return s3(frame)
-- 		end, function(frame)
-- 			s1(frame)
-- 			s2(frame)
-- 			s3(frame)
-- 			return s4(frame)
-- 		end
-- 	end, ...}
-- end
parens8[[
(fn (closures) ((fn (ops loopfn) (select -1
	(set loopfn (fn (i op) (when i (loopfn (select 2
		(rawset builtin op (fn (lookup e1 e2 e3)
			(select i (closures (compile_n lookup e1 e2 e3)))
		))
		(inext ops i)
	)))))
	(loopfn (inext ops))
)) (split "+,-,*,/,\,%,^,<,>,<=,>=,==,~=,..,or,and,not,#,[]")))
]](function(a1, a2, a3) return
	function(f) return a1(f)+a2(f) end,
	a2 and function(f) return a1(f)-a2(f) end
		or function(f) return -a1(f) end,
	function(f) return a1(f)*a2(f) end,
	function(f) return a1(f)/a2(f) end,
	function(f) return a1(f)\a2(f) end,
	function(f) return a1(f)%a2(f) end,
	function(f) return a1(f)^a2(f) end,
	function(f) return a1(f)<a2(f) end,
	function(f) return a1(f)>a2(f) end,
	function(f) return a1(f)<=a2(f) end,
	function(f) return a1(f)>=a2(f) end,
	function(f) return a1(f)==a2(f) end,
	function(f) return a1(f)~=a2(f) end,
	function(f) return a1(f)..a2(f) end,
	function(f) return a1(f) or a2(f) end,
	function(f) return a1(f) and a2(f) end,
	function(f) return not a1(f) end,
	function(f) return #a1(f) end,
	a3 and function(f) a1(f)[a2(f)] = a3(f) end
		or function(f) return a1(f)[a2(f)] end
end)

parens8[[
(foreach (split "+,-,*,/,\,%,^,..") (fn (op)
	(rawset builtin (.. op "=") (fn (lookup e1 e2)
		(compile (pack "set" e1 (pack op e1 e2)) lookup)
	))
))
]]

-- if you don't feel like writing IIFEs, this writes them for you
-- (let ((a 42) (b "foo")) (print (.. b a)))
parens8[[
(rawset builtin "let" (fn (lookup exp2 exp3) (
	(fn (names values) (select 2
		(foreach exp2 (fn (binding) (id
			(add names (rawget binding 1))
			(add values (rawget binding 2))
		)))
		(compile (pack (pack "fn" names exp3) (unpack values)) lookup)
	))
	(pack) (pack)
)))

(rawset builtin "loop" (fn (lookup exp2 exp3) (compile
	(pack (pack "fn" (pack "__ps8_loop") (pack "id"
		(pack "set" "__ps8_loop" (pack "fn" (pack)
			(pack "when" exp2 (pack "__ps8_loop" exp3))
		))
		(pack "__ps8_loop")
	)))
	lookup
)))
]]

-- the "loop" builtin is a "poor man's while", implemented as a tail recursion.
-- thanks to lua, such an implementation will not blow up the stack.
-- if you're really strapped for tokens, it will at least save you the headache
-- of implementing a tail recursion loop correctly yourself.

-- this is what the generated code looks like:
-- (fn (__ps8_loop) (id
-- 	(set __ps8_loop (fn () 
-- 		(when exp2 (__ps8_loop exp3))
-- 	))
-- 	(__ps8_loop)
-- ))

-- if you *really* need proper loops and can justify the token cost however...

-- (while (< x 3) (set x (+ 1 x))
parens8[[
(fn (closure) (rawset builtin "while" (fn (lookup cond body)
	(closure (compile_n lookup cond body))
)))
]](function(a1, a2) return function(frame)
	while (a1(frame)) a2(frame)
end end)

-- `foreach` should take care of your collection traversal needs, but if for
-- some reason you think doing numeric loops in parens-8 is a good idea (it
-- usually isn't), there's a builtin for it:

-- (for (i 1 10 2) (body))
-- (for ((k v) (pairs foo)) (body))
-- 79 tokens for the lot, each syntax can be disabled individually
parens8[[
(fn (closures) (rawset builtin "for" (fn (lookup args body)
	(when (rawget args 3)
		(select 1 (closures
			(compile (pack "fn" (pack (rawget args 1)) body) lookup)
			(compile_n lookup (unpack args 2))))
		(select 2 (closures
			(compile (pack "fn" (rawget args 1) body) lookup)
			(compile (rawget args 2) lookup)))
	)
)))
]](function(cbody, a, b, c) return
	function(frame) -- numeric for loop (28 tokens)
		local body = cbody(frame)
		for i = a(frame), b(frame), c and c(frame) or 1 do
			body(i)
		end
	end,
	function(frame) -- generic for loop (41 tokens)
		local body, next, state = cbody(frame), a(frame)
		local function loop(var, ...)
			if (var == nil) return
			body(var, ...)
			return loop(next(state, var))
		end
		return loop(next(state))
	end
end)
-->8



function update_cards()
    local max_y = ceil(#cards/5)
    
	local prev_cursor_x = cursor_x
	local prev_cursor_y = cursor_y
    if btnp(⬅️) then cursor_x = max(1, cursor_x - 1) end
    if btnp(➡️) then cursor_x = min(5, cursor_x + 1) end
    if btnp(⬆️) then cursor_y = max(1, cursor_y - 1) end
    if btnp(⬇️) then cursor_y = min(max_y, cursor_y + 1) end
    if btnp(🅾️) then  load("#demons_wrapper") end
    local selected_index = (cursor_y-1)*5 + cursor_x
	if selected_index > #cards then
		cursor_x = prev_cursor_x
		cursor_y = prev_cursor_y
	end
    for i=1,#cards do
        local target_offset = (i == selected_index) and -4 or 0
        card_y_offsets[i] = lerp(card_y_offsets[i] or 0, target_offset, 0.3)
    end

	camera_ty = cursor_y*24 - 48
	camera_y = lerp(camera_y, camera_ty, 0.2)
	camera_y = max(0, camera_y)
	local ty=0
	local selected_index = (cursor_y-1)*5 + cursor_x
	if selected_index <= #cards then
		local c = cards[selected_index]
		if is_card_seen(c) then
			ty=73
			if c.name == "twin" then
				ty-=6
			end
		else
			ty=110
		end
	end
	desc_y = lerp(desc_y, ty, 0.2)
end

function update_enemies()

	if btnp(🅾️) then
		load("#demons_wrapper")
		return
	end

	local ci = enemies[enemy_index].deck[enemy_card_index]
	local c = cards[ci]
	if c then
		if is_card_seen(c) and is_enemy_defeated(enemy_index) then
			ty=73
		else
			ty=110
		end
	end

	desc_y = lerp(desc_y, ty, 0.2)

	for i=1,#enemies do
		if not enemy_card_y_offsets[i] then
			enemy_card_y_offsets[i] = {}
		end
		for j=1,#enemies[i].deck do
			local target_offset = (i == enemy_index and j == enemy_card_index) and -4 or 0
			enemy_card_y_offsets[i][j] = lerp(enemy_card_y_offsets[i][j] or 0, target_offset, 0.3)
		end
	end

	if btnp(⬇️) then
		enemy_index = min(#enemies, enemy_index + 1)
		enemy_card_index = mid(1, enemy_card_index, #enemies[enemy_index].deck)
	end
	if btnp(⬆️) then
		enemy_index = max(1, enemy_index - 1)
		enemy_card_index = mid(1, enemy_card_index, #enemies[enemy_index].deck)
	end
	if btnp(➡️) then
		enemy_card_index = min(#enemies[enemy_index].deck, enemy_card_index + 1)
	end
	if btnp(⬅️) then
		enemy_card_index = max(1, enemy_card_index - 1)
	end

	camera_y = lerp(camera_y, 34*enemy_index - 44, 0.2)
	enemy_card_x_offset = lerp(enemy_card_x_offset, 32-enemy_card_index * 20, 0.2)
end

function _draw()
	cls()
	memcpy(0x6000,0x8000,128*128/2)
	if view_enemies then
		draw_enemies()
	else
		draw_cards()
	end
end

function _update60()
	if view_enemies then
		update_enemies()
	else
		update_cards()
	end
end

function draw_enemies()
	camera(0, camera_y)
	local len = print(count_defeated().." / "..#enemies.." enemies defeated", 0, -100, 7)
	print(count_defeated().." / "..#enemies.." enemies defeated", 64-len/2, 1, 7)
	print("press 🅾️ to go back", 23, 12, 5)
	local y = 24
	for i, e in ipairs(enemies) do
		
		draw_enemy(e, 2, y-3, not is_enemy_defeated(i) )
		for j, ci in ipairs(e.deck) do
			local c = cards[ci]
			local offset = ((enemy_card_y_offsets[i] or {})[j]) or 0
			draw_card({
				c=c,
				x=14+j*20 + enemy_card_x_offset,
				y=y+16+offset,
				hidden=not is_card_seen(c) or not is_enemy_defeated(i)
			})
		end

		if not is_enemy_defeated(i) then 
			print("???", 32, y+4, 0)
		else
			local x = print(e.name.." - ", 32, y+4, 7)
			if is_enemy_ngp_defeated(i) then
				print("defeated+",  x, y+4, 14)
			else 
				print("defeated", x, y+4, 7)
			end
		end
	
		y += 34
	end
	camera(0, 0)
	fillp(▒)
	rectfill(0, desc_y, 128, 128, 0)
	fillp()
	rectfill(0, desc_y+5, 128, 128, 0)
	local ci = enemies[enemy_index].deck[enemy_card_index]
	local c = cards[ci]
	if c then
		if is_card_seen(c) and is_enemy_defeated(enemy_index) then
			draw_summary(c, desc_y+7, true)
		else
			print("???", 58, desc_y+9, 7)
		end
	end
end

function draw_cards()
	local str=tostr(count_discovered()).." / "..tostr(#cards).. " demons discovered"
	local len = print(str, 0,-6)
	camera(0, camera_y)
	print(str, 64-len/2, 4, 7)
	print("press 🅾️ to go back", 23, 12, 5)

	for i, c in ipairs(cards) do
		local x = (i-1)%5*24+8
		local y = ceil(i/5)*24
		if card_y_offsets[i] and card_y_offsets[i] < -.1 then
			line(x+1, y+14, x+14, y+14, 0)
		end
		y += card_y_offsets[i]
		draw_card({
			c=c,
			x=x,
			y=y,
			hidden=not is_card_seen(c)
		})
	end
	camera(0, 0)
	fillp(▒)
	rectfill(0, desc_y, 128, 128, 0)
	fillp()
	rectfill(0, desc_y+5, 128, 128, 0)
	local selected_index = (cursor_y-1)*5 + cursor_x
	if selected_index <= #cards then
		local c = cards[selected_index]
		if is_card_seen(c) then
			draw_summary(c, desc_y+7, true)
		else
			print("???", 58, desc_y+9, 7)
		end
	end
end

-->8


--cards

types={
	beast=9,
	ghost=12,
	object=15,
	elemental=14,
}
type_desc={
	beast={"can't block ghosts"},
	ghost={"can't be blocked by beasts","or by unpossessed objects.","possess allied objects on row"},
	object={"can't block ghosts or","attack if unpossessed."},
	elemental={}
}
function foreach_rc(f)
	local acc=0
	for i=1,3 do
		for actor in all{player,opp} do	
			local row = actor.rows[i]
			for rc in all(row) do
				acc+=(f(rc,actor,i) or 0)
			end
		end
	end
	return acc
end
function foreach_hc(actor, f)
	local acc=0
	for hc in all(actor.h_manager.cards) do
		acc+=(f(hc) or 0)
	end
	return acc
end
cards={}
void={}
enemies={}
--30,30,30,30,30,14,14,14,8,8,3,4,6
cards={}
void={}
enemies={}
--30,30,30,30,30,14,14,14,8,8,3,4,6
parens8[[
(set enemies (table))

(add enemies (table 
	(max_hp 8) 
	(name "bug catcher")
	(facex 0) (facey 96) (facealt 0)
	(deck (split "30,30,30,8,8,18,18,13,41,41"))
))
(add enemies (table 
	(max_hp 12) 
	(name "mystic")
	(facex 0) (facey 96) (facealt 1)
	(deck (split "11,11,1,1,4,4,22,7,17,10"))
))
(add enemies (table
	(max_hp 15)
	(name "necromancer")
	(facex 32) (facey 96) (facealt 0)
	(deck (split "11,11,1,1,4,4,5,5,6,6,22,7,17,32,39,47,47,52"))
))

(add enemies (table
	(max_hp 18)
	(name "elementalist")
	(facex 32) (facey 96) (facealt 1)
	(deck (split "18,18,13,13,24,42,9,9,27,27,26,26,25,23,23,34,21,50"))
))

(add enemies (table
	(max_hp 20)
	(name "wizard")
	(facex 64) (facey 96) (facealt 0)
	(deck (split "3,3,16,16,14,28,28,19,29,10,33,20,12,15,2,49"))
))
(add enemies (table 
  (max_hp 22) 
  (name "beast master")
	(facex 64) (facey 96) (facealt 1)
  (deck (split "8,8,13,13,28,19,9,9,35,40,34,21,45,48"))
))

(add enemies (table
	(max_hp 24)
	(name "void caster")
	(facex 96) (facey 96) (facealt 0)
	(deck (split "18,18,43,43,43,28,28,37,44,20,31,31"))
))

(add enemies (table 
  (max_hp 25) 
  (name "artificer")
	(facex 96) (facey 96) (facealt 1)
  (deck (split "1,1,6,6,22,22,5,5,4,4,7,7,17,17,32,38,38,20,51,52"))
))


(add enemies (table 
  (max_hp 26) 
  (name "archmage")
	(facex 96) (facey 64) (facealt 0)
  (deck (split "8,8,16,16,36,35,29,27,24,31,37,25,33,40,15,2,21,34,46"))
))

(set void (table 
	(name "void") (s 78) (atk 1) (def 1) (cost 1) (type "elemental")
	(desc "you ran out of cards...")
))

(set goblin (table
  (name "goblin") (s 53) (atk 3) (def 5) (cost 6) (type "beast")
  (desc "summon goblin in every row")
  (on_summon (fn (actor rc row_i)
    (for (i 1 3)
        (gl_summon actor goblin i 1 1))))))

(set bones (table 
  (name "bones") (s 23) (atk 1) (def 3) (cost 1) (type "ghost") (start_count 2) ))
(set stone (table 
  (name "stone") (s 59) (atk 1) (def 5) (cost 0) (type "object")))
(set swarm (table 
    (name "swarm") (s 11) (atk 2) (def 2) (cost 1) (type "beast") (start_count 2)
    (desc "50% chance to draw swarm")
    (on_summon (fn (actor)
      (when (> (rnd) 0.5)
        (actor.h_manager.add_to_hand actor.h_manager swarm))))))
(set flame (table
		(name "flame") (s 55) (atk 3) (def 3) (cost 4) (type "elemental")
		(desc "2 damage to all foes")
		(on_summon (fn (actor rc row_i)
			(seq
				(foreach_rc (fn (target_rc owner row)
					(when (~= owner actor)
						(seq 
							(set target_rc.hp (- target_rc.hp 2))
							(set target_rc.damaged_at (time))
						)
					)
				))
				(ssfx 37)
				(wait 0.5)
				(clear_dead)
			)
		))

		(ai_will_play (fn (actor)
			(>= (foreach_rc (fn (rc owner)
				(* (when (~= owner actor) 1 -1) (when (<= rc.hp 2) rc.c.cost 1))
			)) 2 )
		))
	))
(add cards bones)
(add cards goblin)
 (add cards (table (name "hellhound") (s 1) (atk 1) (def 5) (cost 1) (type "beast") (start_count 2)))
  (add cards (table (name "spirit") (s 3) (atk 1) (def 5) (cost 2) (type "ghost") (start_count 2)))
  (add cards (table (name "blade") (s 5) (atk 3) (def 4) (cost 2) (type "object") (start_count 1)))
  (add cards (table (name "orb") (s 7) (atk 2) (def 6) (cost 2) (type "object") (start_count 1)
		(desc "draw a card")
		(on_summon (fn (actor)
			(gl_draw_card actor)
		))
  ))
  (add cards (table (name "automata") (s 9) (atk 3) (def 12) (cost 3) (type "object") (start_count 1)))
  (add cards  (table (name "imp") (s 17) (atk 2) (def 3) (cost 1) (type "beast") (start_count 2)))
  (add cards (table (name "bat") (s 19) (atk 3) (def 5) (cost 3) (type "beast") (start_count 2)))
  (add cards (table (name "wil'o") (s 21) (atk 3) (def 8) (cost 4) (type "ghost") (start_count 2)))
  (add cards(table (name "furniture") (s 25) (atk 1) (def 6) (cost 0) (type "object") (start_count 2)))
  (add cards(table (name "'geist") (s 27) (atk 3) (def 8) (cost 5) (type "ghost") 
	(desc "kill unpossessed objects")
	(on_summon (fn (actor rc row_i)
		(foreach_rc (fn (target_rc owner row)
			(when (and (== target_rc.c.type "object") (not target_rc.possessed))
				(seq 
					(set target_rc.hp 0)
					(set target_rc.damaged_at (time))
					(ssfx 37)
					(wait 0.6)
					(clear_dead)
				)
			)
		))
	))
  (start_count 1)))
  (add cards(table (name "viper") (s 39) (atk 2) (def 2) (cost 3) (type "beast") (start_count 1)
	(desc "hits to opponent deal double damage")
	(double_damage_to_opponent 1)
  ))
  (add cards(table (name "'shroom") (s 41) (atk 1) (def 6) (cost 2) (type "elemental")(start_count 1)))
  (add cards(table (name "lich") (s 43) (atk 3) (def 14) (cost 6) (type "ghost")))
  (add cards(table (name "slime") (s 33) (atk 1) (def 8) (cost 2) (type "beast")(start_count 1)))
  (add cards(table (name "blinky") (s 35) (atk 1) (def 8) (cost 3) (type "ghost")(start_count 1)))
  (add cards swarm)
  (add cards  (table
    (name "jelpi") (s 13) (atk 1) (def 8) (cost 3) (type "beast") (start_count 1)
    (desc "heal 4")
    (on_summon (fn (actor)
      (set actor.hp (+ actor.hp 4))
	))
))

	(add cards (table
		(name "wand") (s 72) (atk 1) (def 8) (cost 5) (type "object")
		(desc "ally's abilities trigger twice")
		(double_abilites_for (fn (card) 1))
	))
	(add cards (table
		(name "gorgon") (s 57) (atk 3) (def 6) (cost 6) (type "beast")
		(desc "turn foes to stone")
		(on_summon (fn (actor rc row_i)
			(foreach_rc (fn (rc owner)
				(when (~= owner actor)
					(seq 
						(set rc.c stone)
						(set rc.hp (min stone.def rc.hp))
						(set rc.possessed nil)
						(set rc.damaged_at (time))
					)
				)
			))
			(ssfx 37)
			(wait 0.6)
			(clear_dead)
		))
	))

	(add cards (table 
		(name "candle") (s 37) (atk 2) (def 2) (cost 2) (type "object") (start_count 1)
		(desc "+1 mana")
		(on_summon (fn (actor)
			(set actor.mana (+ actor.mana 1))
		))
	))

	(add cards (table
		(name "zap") (s 45) (atk 3) (def 1) (cost 4) (type "elemental")
		(desc "clear row")
		(on_summon (fn (actor rc row_i)
			(foreach_rc (fn (target_rc owner row)
				(when (and (== (abs row_i) (abs row)) (~= target_rc rc))
					(seq 
						(set target_rc.hp 0)
						(set target_rc.damaged_at (time))
					)
				)
			))
			(ssfx 37)
			(wait 0.6)
			(clear_dead)
		))
	))

	(add cards (table
		(name "cactus") (s 68) (atk 1) (def 8) (cost 3) (type "elemental")
		(desc "deal 3 damage to opponent")
		(on_summon (fn (actor)
			(gl_damage_player (when (== actor player) opp player) 3)
		))
	))

	(add cards (table
		(name "gargoyle") (s 84) (atk 3) (def 14) (cost 4) (type "elemental")
		(desc "costs 5 life")
		(on_summon (fn (actor)
			(gl_damage_player actor 5)
		))
		(ai_will_play (fn (actor)
			(let ((foe (when (== actor player) opp player)))
				(and (>= actor.hp foe.hp) (>= actor.hp 10))
			)
		))
	))
	(add cards flame)


	(add cards (table
    	(name "relic") (s 51) (atk 1) (def 5) (cost 3) (type "object")
    	(desc "kill all ghosts")
    	(on_summon (fn (actor)
      		(foreach_rc (fn (rc owner i)
        		(when (== rc.c.type "ghost")
					(seq
						(set rc.hp 0)
						(set rc.damaged_at (time))
						(ssfx 37)
						(wait 0.6)
						(clear_dead)
					)
				)
			))
		))
		(ai_will_play (fn (actor)
			(>= (foreach_rc (fn (rc owner i)
				(when 
					(== rc.c.type "ghost") 
					(seq 
						(* (when (~= owner actor) 1 -1) rc.c.cost)
					)
					0
				)
			)) 3 )
		))
	))
		
	(add cards (table
		(name "toad") (s 86) (atk 1) (def 4) (cost 2) (type "beast") (start_count 1)
		(desc "draw a card")
		(on_summon (fn (actor)
			(gl_draw_card actor)
		))
	))


	(add cards (table
		(name "smog") (s 88) (atk 3) (def 1) (cost 3) (type "elemental")
		(desc "can't block")
		(can_defend (fn ()
			false
		))
	))

	(add cards (table
		(name "bug") (s 92) (atk 2) (def 1) (cost 1) (type "beast") (start_count 2)
		(desc "can't block beasts or ghosts")
		(can_defend (fn (rc attacker)
			(when (== attacker.c.type "beast")
				false
				1
			)
		))
	))

	
	(add cards (table
		(name "gnome") (s 76) (atk 1) (def 1) (cost 4) (type "beast")
		(desc "discard all cards, draw 5")
		(on_summon (fn (actor)
			(foreach actor.h_manager.cards (fn (hc)
				(when (~= hc.c "endturn")
					(seq
						(actor.h_manager.remove actor.h_manager hc.c)
						(wait 0.1)
					)
				)
			))
			(for (i 1 5)
				(seq
					(gl_draw_card actor)
					(wait 0.1)
				)
			)
		))
		(ai_will_play (fn (actor)
			(when (== current_enemy.name "void caster")
				(seq
					(< (foreach_hc actor (fn (hc) (when (== hc.c.name "portal") 1 0))) 1)
				)
				(and (<= (rawlen actor.h_manager.cards) 3) (>= (rawlen actor.deck) 5))
			)
		))
	))

	(add cards (table
		(name "skelly") (s 29) (atk 2) (def 7) (cost 4) (type "ghost")  (start_count 1)
		(desc "summon bones")
		(on_summon (fn (actor _rc i)
			(gl_summon actor bones i 1)
		))
	))

	(add cards (table
		(name "reaper") (s 94) (atk 3) (def 7) (cost 5) (type "ghost")
		(desc "kill all injured")
		(on_summon (fn (actor)
			(foreach_rc (fn (rc owner i)
				(when (< rc.hp rc.c.def)
					(seq
						(set rc.hp 0)
						(set rc.damaged_at (time))
						(ssfx 37)
						(wait 0.25)
						(clear_dead)
					)
				)
			))
		))
	))

	(add cards (table
		(name "dragon") (s 100) (atk 3) (def 10) (cost 6) (type "beast")
		(desc "summon flame")
		(on_summon (fn (actor _rc i)
			(gl_summon actor flame i 1)
		))
	))

	(add cards (table
		(name "mimic") (s 102) (atk 3) (def 8) (cost 3) (type "beast")
		(desc "can't attack unless hurt")
		(can_attack (fn (rc)
			(< rc.hp rc.c.def)
		))
	))

	(add cards (table
		(name "phish") (s 70) (atk 1) (def 6) (cost 3) (type "beast")
		(desc "steal a card")
		(on_summon (fn (actor)
			(gl_steal_card actor)
		))
	))

	(add cards (table
		(name "storm") (s 104) (atk 2) (def 8) (cost 4) (type "elemental")
		(desc "allied elemental's abilities trigger twice")
		(double_abilites_for (fn (card) (== card.type "elemental")))
	))	

	(add cards (table
		(name "magnet") (s 74) (atk 1) (def 4) (cost 4) (type "object")
		(desc "draw an object from your deck")
		(on_summon (fn (actor)
			(gl_tutor actor (fn (c) (== c.type "object")))
		))
	))

	(add cards (table
		(name "'nomicon") (s 90) (atk 1) (def 4) (cost 4) (type "object")
		(desc "draw an ghost from your deck")
		(on_summon (fn (actor)
			(gl_tutor actor (fn (c) (== c.type "ghost")))
		))
	))
	(add cards (table
		(name "devil") (s 106) (atk 3) (def 6) (cost 6) (type "beast")
		(desc "draw an 4✽+ card from your deck")
		(on_summon (fn (actor)
			(gl_tutor actor (fn (c) (>= c.cost 4)))
		))
	))
	
	(add cards (table
		(name "bait") (s 108) (atk 1) (def 1) (cost 2) (type "object") (start_count 1)
		(desc "draw up to 3 1✽ cards from your deck")
		(on_summon (fn (actor)
			(for (i 1 3)
				(seq
					(gl_tutor actor (fn (c) (== c.cost 1)))
					(wait 0.25)
				)
			)
		))
	))

	(add cards (table
		(name "sapling") (s 110) (atk 0) (def 3) (cost 3) (type "elemental")
		(desc "heal all allies")
		(on_summon (fn (actor)
			(foreach_rc (fn (rc owner i)
				(when (and (== owner actor) (< rc.hp rc.c.def))
					(seq
						(set rc.hp rc.c.def)
						(set rc.damaged_at (time))
					)
				)
			))
		))
		(ai_will_play (fn (actor)
			(>= (foreach_rc (fn (rc owner i)
				(when 
					(== owner actor) 
					(- rc.c.def rc.hp)
					0
				)
			)) 6 )
		))
	))

	(add cards (table
		(name "portal") (s 116) (atk 0) (def 8) (cost 3) (type "elemental")
		(desc "each void you summon deals 2 damage to opponent")
		(on_void (fn (rc actor)
			(gl_damage_player (when (== actor player) opp player) 2)
		))
	))

	(add cards (table
		(name "cultist") (s 118) (atk 3) (def 6) (cost 5) (type "beast")
		(desc "draw each time you summon a void")
		(on_void (fn (rc actor)
			(gl_draw_card actor)
		))
	))

	(set tentacle (table
		(name "tentacle") (s 124) (atk 2) (def 4) (cost 0) (type "beast")
	))

	(add cards (table
		(name "kraken") (s 122) (atk 2) (def 6) (cost 3) (type "beast")
		(desc "summon two 2/4 tentacles")
		(on_summon (fn (actor _rc i)
			(gl_summon actor tentacle (* -1 i) 1)
			(gl_summon actor tentacle i 1)
		))
	))

	(add cards (table
		(name "raven") (s 120) (atk 2) (def 2) (cost 4) (type "beast")
		(desc "+1 mana for each ghost in hand")
		(on_summon (fn (actor)
			(set actor.mana (+ actor.mana (foreach_hc actor (fn (hc)
				(when (== hc.c.type "ghost") (seq
					(set hc.ability_at (time))
					(ssfx 41)
					(wait 0.25)
					1
				) 0)
			))))
		))
		(ai_will_play (fn (actor)
			(>= (foreach_hc actor (fn (hc)
				(when (== hc.c.type "ghost") 1 0)
			)) 2)
		))
	))

	(set corpse (table
		(name "corpse") (s 130) (atk 3) (def 6) (cost 4) (type "object")
		(desc "on kill: summon corpse")
		(on_kill (fn (actor rc dead_rc row)
			(gl_summon actor corpse row 1)
		))
	))
	(add cards corpse)

	(add cards (table
		(name "cryptid") (s 128) (atk 2) (def 8) (cost 6) (type "beast")
		(desc "on kill: deal 1 damage to opponent for each beast in hand")
		(on_kill (fn (actor rc dead_rc row)
			(foreach_hc actor (fn (hc)
				(when (== hc.c.type "beast") (seq
					(ssfx 41)
					(set hc.ability_at (time))
					(wait 0.25)
					(gl_damage_player (when (== actor player) opp player) 1)
				))
			))
		))
	))

	(add cards (table
		(name "familiar") (s 126) (atk 1) (def 3) (cost 3) (type "beast")
		(desc "random effect")
		(on_summon (fn (actor rc i)
			(let ((opts (table)) (og_c rc.c))
				(seq
					(foreach cards (fn (c)
						(when c.on_summon (add opts c))
					))
					(let ((c (rnd opts)))
						(seq 
							(set rc.c c)
							(set rc.hp c.def)
							(ssfx 43)
							(set rc.ability_at (time))
							(wait .4)
							(c.on_summon actor rc i)
							(wait 0.3)
							(set rc.c og_c)	
							(set rc.hp og_c.def)
						)
					)
				)
			)
		))
	))

	(add cards (table
		(name "yeti") (s 134) (atk 1) (def 6) (cost 3) (type "elemental")
		(desc "freeze all for 2 turns")
		(on_summon (fn (actor)
			(foreach_rc (fn (rc owner i)
				(seq
					(set rc.damaged_at (time))
					(set rc.frozen 2)
				)
			))
			(ssfx 37)
		))

		(ai_will_play (fn (actor)
			(>= (foreach_rc (fn (rc owner i)
				(when 
					(can_attack rc actor)
					(when (== actor owner) 1 -1)
					0
				)
			)) 3 )
		))
	))

	(add cards (table
		(name "sheet") (s 132) (atk 2) (def 4) (cost 3) (type "ghost")
		(desc "possess all allied objects")
		(on_summon (fn (actor)
			(foreach_rc (fn (rc owner i)
				(when (and (== owner actor) (and (== rc.c.type "object") (not rc.possessed)))
					(seq 
						(set rc.possessed 1)
						(set rc.possessed_at (time))
						(ssfx 40)
						(wait 0.5)
					)
				)
			))
		))
	))

	
(set twin (table 
  (name "twin") (s 136) (atk 1) (def 1) (cost 1) (type "ghost") (start_count 1) 
	  (desc "summon twin to back of middle row")
	  (on_summon (fn (actor)
		(gl_summon actor twin -2 1 1)
	  ))
  ))
  (add cards twin)
]]
-->
function mark_card_seen(card)
    -- Find card index in the cards array
    local card_index = 0
    for i,c in ipairs(cards) do
        if c == card then
            card_index = i
            break
        end
    end
    
    if card_index == 0 then return end
    
    local byte_offset = (card_index - 1) \ 8  -- Integer division
    local bit_position = (card_index - 1) % 8
    
    local addr = 0x5e00 + 65 + byte_offset
    local current = peek(addr)
    
    local new_value = current | (1 << bit_position)
    

    poke(addr, new_value)
end

function is_card_seen(card)
	-- Find card index in the cards array
	local card_index = 0
	for i,c in ipairs(cards) do
		if c == card then
			card_index = i
			break
		end
	end
	
	if card_index == 0 then return false end
	
	local byte_offset = (card_index - 1) \ 8  -- Integer division
	local bit_position = (card_index - 1) % 8
	
	local addr = 0x5e00 + 65 + byte_offset
	local current = peek(addr)
	
	return (current & (1 << bit_position)) > 0
end

function is_enemy_defeated(index) 
	return peek(0x5e00+73+index) >= 1
end

function is_enemy_ngp_defeated(index)
	return peek(0x5e00+73+index) >= 2
end

function count_defeated()
	local count = 0
	for i=1,9 do
		if is_enemy_defeated(i) then
			count += 1
		end
	end
	return count
end

function count_discovered()
	local count = 0
	for i,c in ipairs(cards) do
		if is_card_seen(c) then
			count += 1
		end
	end
	return count
end
function lerp(from,to,p)
	return from*(1-p)+to*p
end
__gfx__
00000000000707000000000000007770000000000000007700000000007777000077770000000000000000000770770000000000070007000070007000000000
00000000007777700007070000077777000077700000078700000077078888700788887000077700000000000770880007707700077777700077777700000000
00700700077787800077777000078778000777770000787000000787787888877888778700778700000777000007777007708800078777800078777800000000
00077000077777770777878000777777007787780007870000007870788877877888778700778700007787007007878000077770077777700077777700000000
00077000077777700777777707777770007777770778700000078700788877877878888700777700007787000777777770078780088880000088880000000000
00700700777777007777777007777700077777700077000007787000078888700788887000777700007777007777700077777777077770000077770000000000
00000000777777007777770077770000777777000707000000770000007777000077770007007070007777007707070077770800077777000777770000000000
00000000070070000700070077000000777000000000000007070000077777700777777007007070070070707007070070070700070000000000070000000000
e00000ee000700070000000000000000077007700770000070000007000077700000000000000000007000000077770000000000000777000000000000000000
0667770e000700070007000770700707777007770770007000770000000787800000077707000000007000000777777000777700007878000007770000000000
0667770e070777707007000770777707770000770000770000770000000777700700787807000000070777007777788707777770007777000078780000000000
e06770ee700787807007777070787807707007070007777000007700070070707700777707077700070777000077788777777887000707000077770000000000
ee070eee700077707007878070078707707777070007777070077770770000000070070707077700070777000788788700777887000000007007070700000000
eee0eeee777770007777777077000077707878077000770000077770007000000007700007077700077777000777877007887887070770700000700000000000
eeeeeeee777777007777770077700777700787070000000000007700000770000007000007777700070007000777700077778770000000000000000000000000
eeeeeeee070007000700070007700770000000000070007000000007000700000000000007000700000000007770000077700000007007000700007000000000
eeeeeeee077777000077700000077700000000000000700000000000000000000000000000777700000000000777777000000000000000000077770000000000
7eeeeeee077778700777870000777770007770000000700000007000000000007000000007887770007777007777777707777770007777000788887000000000
77eeeeee787777770777777007777777077777000000000000000000700007777000000007887870078877707788778877777777007878000787877000000000
777eeeee777887777877777707778778777777700007770000077700700078788000077707777770078878707788778877777777000777000078887000000000
7777eeee787887877778878707777777777877800007770000077700800077777000787800888800077777707777787777887788000777000078887000000000
666eeeee788887877878878707777777777777700707770007077700700077707000777700787800007878000077777077777877000770000078870000000000
66eeeeee787887877888778700707070777777700778777007788770700777707707777000777700007777000000707000777770007770000788700000000000
6eeeeeee777777777777777700000000707070700777777007777770777777000777770000700700070000700000000000007070007000000787000000000000
07000000000000000000000000000000007070700000000070000000007000000007000000707000000707000000000000770000000000000000000000000000
70700000000000000000000007070070000000007077770070000000007700000007700070070700070070700077000000777000077770000777700000000000
07000000000777000000000000000000070000707078880000777700707770000007770007777700007777700077700000778700778777007787770000000000
00000000007777700070000070000007000000000077870070788807777777007077770000787800000787800077870000778700787877007878770000000000
00000000007778700007777000000000007007007088880700778700777877707777777000777700000777700077870007777870787770007877770000000000
00000000007777700070000007000070000770000077770000888800778877707777787000888800007888000777787007777870778707077787000000000000
00000000000777000000000000077000000770000077770000777700778887707787887000777700000777000777787007777770077807070778707000000000
00000000000000000000000000077000000000000070070000700700077888700788887000077000000770000777777000000000007777770077777000000000
eee7774774777eeeee777777777777ee000770000007700000000000077700000007700000000070007777700007777700077000000770000000000000077000
ee744478874447eee70000000000007e007777000077770007770000777770700070070070077000078887700078887700777700007777000007700000700700
e74477477477447e7077777777777707707878000078780777777007777787700070070000700700788877700788877700787800008787000000000007777770
74474444444474477070000000000707777777077077777777778777777777700007000000700707788700000788700000777700007777000707707070700707
74744444444447477070000000000707777787777777877777777777787877700000700000070000788700000788700070888807008888000707707070700707
74744444444447477070000000000707007777777777770078787777778777700000700070007070788877700788877700778700707787070000000007777770
74744444444447477070000000000707007777000077770077877007777770700000700000007000078887700078887700777700007777000007700000700700
74744444444447477070000000000707007777000077770007770000077700000000700000007000007777700007777700700700007007000000000000077000
74744444444447477070000000000707000000000777777000000000000000000000000000000000077777000077777000700700000000007707700000000000
74744444444447477070000000000707077777707788788000000000000000000077000000077000788888700788888700070070007007000707870077077000
74744444444447477070000000000707778878807777777700070700000000000777770000777770787778700787778700777770000700700077870007078700
74744444444447477070000000000707777777777070707000787870000707007777777777777777788788700788788707788780007777700787770000778700
74474444444474477070000000000707707070707000000000777770007878700000000000000000787778700787778707788780077887800778777007877700
e74477777777447e7077777777777707700000007000000007777770007777700000770000077000787878700787878707777770077887800777877007787770
ee744444444447eee70000000000007e770707077707070770070070077777700007777000777700788888700788888777777770777777700777777007778770
eee7777777777eeeee777777777777ee777777777777777777077077770770770000000000000000077777000077777077777700777777700777777077777777
00000000000000000000000000000000000000000000000000000000078777700077770007777000070000700000000000000000000000000000000000000000
00000007000070000000000000000000000070070000000000000000777877770078780007878000077007700700007000000000000000007700000000000077
00000077000777000000000000000000770077770000700707877770000000000077770007777000007777000770077000000000778700007770007777000777
00000770007777700000000000000000777078780000777777787777000700700000000000000000007878000077770077870000878770000770077777700770
70007700000070000000000000000000077077770770787888888888000000000070070007007000707777070078780087877000778777000007077007707000
77077000000070000000000000000000007778807788777777787887777878870077700000770000078888700077770077877700778787700007700000070000
07770000000070000000000000000000777778708887888077787777777877770007000000070000008778007088880777878770788777870007000000070000
00700000007770000000000000000000770070707700707077787777777877770000700000700000077007700770077078877787000000000007000000070000
00000000000000000000000000000000000777000077700007777000000000000000000000000000007777000000000000777700000000000007070000070700
00000000000000000000000000000000070700700070000077777700077770007770000000000770077777700077770007770000000000000007777000077770
00000000000000000000000000000000700000000000007777788870777777000777077000777877777777770777777077700000000777007007878007078780
00000000000000000000000000000000700770777007700777878787777888700077787707777770777887787777777777700000007777707007777007077770
00000000000000000000000000000000770770077007700777888887778787870007777077787770777887787778877877770000077700777000880007008800
00000000000000000000000000000000000000077700000007777770778888870077777000080800777777777778877807777000077700070707770007077700
00000000000000000000000000000000070070700000070007777770077777700008080000070700077777707777777700777700077770000777777007777770
00000000000000000000000000000000007770000007770077777770777777770007070000000000777007777777777700777700007777000070707000707070
070000070000000000777000000000000007770000077700000777000000000007077700070777000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
077000770700000707878000007770000778780000787870007878000007770070787800707878000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
007777700770007707777000078780000777777007777770007777000078780000777700007777070000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
077877870077777000880000077770000777777007777770007787000077770007088007000880000000000000000000eeeeeeeeeeee00000000eeeeeeeeeeee
007788700778778707777707008800000777777007777700077777700077870000778700707787000000000000000000eeeeeeeeeee0700777770eeeeeeeeeee
077777700777887007700707077777070077770007777700077787700777777007777770077777700000000000000000eeeeeeeeee070777777770eeeeeeeeee
777777707777777008080000077007077077700070777000077777700777877000800800080080000000000000000000eeeeeeeee07007777700770eeeeeeeee
707000707070007007070000700070000777700007777000007777007777777700700700070070000000000000000000eeeeeeeee07077777770770eeeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeee07707777777070eeeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeee07000777700070eeeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeee07077077077700eeeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeee00077077077700eeeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeee00777777777700eeeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeee0000007777000700eeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeee070777707707777070eeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeee070700077770007070eeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeee070777707707707070eeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeee070777077770707070eeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeee0077070770707700eeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeee07707700770070eeeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeee0707770000777070eeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeee0707707777077070eeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeee0707077007707070eeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeee0770770000770770eeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeee077777707707777770eeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeee00770777700777770700eeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeee0707007777777770707070eeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee077070770777707707770770eeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee070070770777707707700070eeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee000007707707770770700000eeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eee00000077077070707707000000eee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ee0000000770770707077070000000ee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccceeeeeeeeeeeeeeeeeeeeeeeeecccccccccceeeeeeeeeeeeeeee222eeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeecccceeeeeeeeeeeeeeeeeeeeeeeeeeecddddceeeeeeeeeeeeeeeeeeeeeecccccccccccccceeeeeeeeeeeeeee2222eee222222222eeeee2eee
eeeeeeeeeeeeeecccccceeeeeeeeeeeeeeeeeeeeeeeeecdddccdceeeeeeeeeeeeeeeeeeeeccc00000000cccceeeeeeeeeeeeeee222222000000002222222eeee
eeeeeeeeeeeeecccccccceeeeeeeeeeeeeeeeeeeeeee01011001dceeeeeeeeeeeeeeeeeeccc0666006660cccceeeeeeeeeeeeee22222077777771022222eeeee
eeeeeeeeeeeec000000ccceeeeeeeeeeeeeeeeeeeee0777777761dceeeeeeeeeeeeeeeeccc066660066660cccceeeeeeeeeeeee222207767777777022eeeeeee
eeeeeeeeeee2060767600ceeeeeeeeeeeeeeeeeeee001777777111cceeeeeeeeeeeeeeecc06666600666660cccceeeeeeeeeeeee2207777777767710eeeeeeee
eeeeeeeeee266667676060ceeeeeeeeeeeeeeeeee06777777777760cceeeeeeeeeeeeeccc06660177006660cccceeeeeeeeeeeee2201017777771110eeeeeeee
eeeeeeeee28606666076660eeeeeeeeeeeeeeeee2607177777716070ceeeeeeeeeeeeecc0666077777706660cccceeeeeeeeeeee2207777711777770222eeeee
eeeeeeee2826666766666062eeeeeeeeeeeeeeee2667777777766770ceeeeeeeeeeeeecc0660777777771660cccceeeeeeeeeeee2267111777711176222222ee
eeeeeee288666666666666662eeeeeeeeeeeeeee0677777677667771cceeeeeeeeeeeccc0607777777777170ccccceeeeeeeeeee220111007700111022222eee
eeeeeee288666667676666662eeeeeeeeeeeeee266110667766000770ceeeeeeeeeeecc066177777777771770cccceeeeeeeeeee220111117711111022eeeeee
eeeeee28880006766670006682eeeeeeeeeeeee260011177661111170ceeeeeeeeeeecc167166677777760671cdcceeeeeeeeeee220100007700001022eeeeee
eeeeee28886666667767666682eeeeeeeeeeeee070000066670000170dceeeeeeeeeccc167000067771000661cdccceeeeeeeeee220110017710011022eeeeee
eeeeee28820000677710000682eeeeeeeeeeeee076100660176111670dceeeeeeeeecc07617000067100060770dccceeeeeeeee2206101107701101602eeeeee
eeeeee28886666777777666682eeeeeeeeeeeee076776600117606770dceeeeeeeeecc06617111667700171770cccceeeeeeeee2016710677776017610eeeeee
eeee228888000677777100668822eeeeeeeeeee266771601117777770ceeeeeeeeeeec06607666767767660760ccceeeeeeeeee20107777177177770102eeeee
eee28288886666777777666688282eeeeeeeeeee2001777117771110ceeeeeeeeeeeec06607777767767771760ccceeeeeeeee220101777011077710102eeeee
eee28282826066667766060628282eeeeeeeeeeee00777767767711cceeeeeeeeeeee2666007770771767116660ceeeeeeeeee222c01777100177710c22eeeee
eeee228888666606716666768822eeeeeeeeeeeee00770110017711cceeeeeeeeeeee2666066777017677706660ceeeeeeeee22eee01777111171710ee22eeee
eeeee2888667666117766676682eeeeeeeeeeeeee00617171711710cceeeeeeeeeeee2860606770000667160660eeeeeeeee2eeeee01777711777710eee2eeee
eeeee2888666667677676666682eeeeeeeeeeeeeec067100000671ccceeeeeeeeeeee2880606706666066160662eeeeeeeeeeeeeee06777666677760eeeeeeee
eeeee2888667666777766666682eeeeeeeeeeeeeecc0666666660cccceeeeeeeeeeee2880606166006606160662eeeeeeeeeeeeeeec071777777170ceeeeeeee
eeeee2888667661111776666682eeeeeeeeeeeeeecc0666117760cccceeeeeeeeeeee2880660660111760660662eeeeeeeeeeeeeeec077111111770ceeeeeeee
eeeeee28866660110017666662eeeeeeeeeeeeeeeccc06676670ccccceeeeeeeeeeee2826666660671666666062eeeeeeeeeeeeeeee067667766760eeeeeeeee
eeeeee28866666676676667662eeeeeeeeeeeeeeeccc00611710ccccceeeeeeeeeeee2828606666006666666082eeeeeeeeeeeeeeeec0666006660ceeeeeeeee
eeeeee22866666601766667602eeeeeeeeeeeeeeeecc00001100cccceeeeeeeeeeeee2828606666666660666082eeeeeeeeeeeeeeeecc06666660cceeeeeeeee
eeeee2220666667666676660002eeeeeeeeeeeeeeeec06001160ccceeeeeeeeeeeee288280660666606606660882eeeeeeeeeeeeeeecd00666600dceeeeeeeee
eee22222000766676676600000222eeeeeeeeeeeeeec06666660ccceeeeeeeeeeeee282261660666606606601082eeeeeeeeeeeeeeecd11111111dceeeeeeeee
ee2222226101001000010016102222eeeeeeeeeeeeec07711771dcceeeeeeeeeeeee200007606606660660601000ceeeeeeeeeeeeecdd17100171ddceeeeeeee
e222222067600010110106661002222eeeeeeeeeccc1667777770cdccceeeeeeeec00110067066060606606100011ccceeeeeeeeccddc17777771cddcceeeeee
02222201076666767767666010102222eeeeecccc00610077110610cccccceeeec1111110671760606066171001111ddeeeeeecccccd1677117761dccccceeee
__label__
000000000000000000000000hhhhhh0000000000000hhh00hhhhhhh0000000000000000000h0000h000000000000000000h0000h000h0000000000h00000h000
0000000000h666l66l666000hh0h0000h0000000000h0h0hhhh0h0h0h000000000h000000000000h000000000000h00000h000000h000000000000h000h00000
00000000006lll6006lll600000h0h00000666l66l6660hh0h0hhh00000666l66l666hhh0000000h0h0777077077700000hh0000h00777077077700h00h00000
0000000006ll66l66l66ll6000h0h000006lll6006lll6l000h0h000006lll6006lll600000000000070007rr700070000hh00hhh070007cc700070h00000000
000000006ll6llllllll6ll6000h0h0006ll66l66l66ll6h0000000006ll66l66l66ll6h00000000070077077077007h00000h000700770770770070hh0000h0
000000006l6lll0000lll6l600hhhh006ll6llllllll6ll6000000006ll6llllllll6ll600000000700700000000700700000h0h7007000000007007h0hh00h0
000000006l6ll000000ll6l6000hhh006l6llllllllll6l60h0000006l6llll0lll0l6l600000000707000000000070700000h0h7070077000000707hh0h0h00
000000006l6l00000000l6l6000hih006l6llllllllll6l6hh0000006l6llll0lll0l6l60000000070707070070707070000000070700770007007070h0ihhh0
00000hh06l6l00000000l6l6000hh0006l6llll000lll6l6hh0000006l6ll0l0000ll6l600000000707070777707070700000000707000007700070700000000
00h0h0h06l6l00000000l6l6000ih0h06l6lll0000lll6l6h0hh00006l6l0ll0000ll6l600000000707070707007070700000000707000077770070700hhh0h0
000hhhh06l6ll000000ll6l6000h00006l6lll0000lll6l6h0h000006l6l0lll000ll6l6000000007070700707070707h000000070700007777007070000h0h0
00hhlhh06l6lll0000lll6l6000h00006l6ll000000ll6l6hhh000006l6l00000llll6l6000000007070770000770707h0000000707070007700070700hh00i0
000h0hh06l6ll000000ll6l6000h00006l6l0l0000l0l6l60l0000006l6l000000lll6l6000h00007070777007770707h0000000707000000000070700hhhh00
000hl0006ll6llllllll6ll6h00000006l6ll00l000ll6l6hh0000006l6ll0lll0lll6l6000h00007070077007700707h0000i0h707000700070070700h0h000
0000hhh006ll66666666ll6lh00000006ll6llllllll6ll6h00000006ll6llllllll6ll6000h00007007000000007007hh00hl0l700700000000700700hhhh00
0000hhh0006llllllllll6hhl000hhh006ll66666666ll60l00h000006ll66666666ll60000h00h0l70077777777007hhh00ll0hh70077777777007000l0h000
00000h000006666666666lhlh000ihh0006llllllllll600h00h00000h6llllllllll600000l00h0hh700000000007hlhh00hl0lhh70000000000700h0hh0000
00000hhh000000000i0hhhlhl00hlhh00hl6666666666h0hi00h00000il6666666666000000hh0l0lhl77777777770hhhh00lhhllhh7777777777000lhh0h000
00000h0h00000h000l0hhlhlhhhhlh00hlhh0l0l0h0lhh00h00h00000lh00h0hh0000000000lhhh0hlhl0lhlhlhhh0hh0h00ilhlh0000hhlll0h0000i000hhh0
0000hih000h00h000hhhlllhlhl0lhh0hllh0lhlhh0lhhh00000000lhllhh0lhhh000000000hhhlhlhlhhlllllllhhhhlh00llhllhh00hilllh00000l000hh00
00000h0000hh0hh00l0ihlhlhhlhihhhhllh0lhlhh0lhhh00000000lhllhh0lh0hhh000000hlhihhhlhlhlilhlilhhhi0000ilhlhh000illhlhh000hih00h000
0000hhh000lh0hlh0hhilhlllhlhlhhhlllh0lhll00llhh00000000llllhhhlhi000lh00h0lllhlhlhllhillllllhhhhl000lllllhhh0illlihh000hl0h00000
0hhhhhh000hl0lh00lhlhlhllhlillhhilih0lhlhl0llhh00000000llllhh0hh0000000000illlihllilililllilhl0hh000llilllhh0lllil0h000lil00h000
hhl0lhh000lh0hlhhhhllllllhlillhhlllh0llll0hllhh0000000lllllhlhlhhhh000h0h0llllllllllllllllllllh0h00hllllllhhlllllllh0hhhllh0hhh0
h0hhhhh000hl0lhh0lhlhlhlhhllilhhillh0lllhhhliihh000000llililihhl00hih00000llllllilililllilllillhh00lilllhlh0ililhlh00lhlhlhh0000
lhlhl0h000l666l66l666illlhlllllhlllhhllllhhllllhh0000hlllllllhllhhhhh000l0lllllllllllllllllllllhhh0lllllllh0lllllll00ihllhh00000
h0ihi000006lll6006lll6illlilllhhlli666l66l666lih00000llllll666l66l666000ihllllillli7770770777lhhhh0lllilllh666l66l666lhlhlh0hh00
lhlhlhh0h6ll66l66l66ll6llllllllhll6lll6006lll6lh00000lllll6lll6006lll600llllllllll70007pp70007lhhh0lllllll6lll6006lll6llll00h000
hhlhhh0h6ll6llllllll6ll6illlilhll6ll66l66l66ll6i000h0llll6ll66l66l66ll6ihlllillli70077077077007lh00lhllli6ll66l66l66ll6lhlh0h000
lhlilhh06l6llllllllll6l6llllllhl6ll6llllllll6ll60000hlll6ll6llllllll6ll6llllllll7007000000007007hh0lllll6ll6llllllll6ll6lih0l00l
lhilhh006l6ll0lllllll6l6llllllhl6l6lll0000lll6l60h00hlll6l6llllllllll6l6llllllll7070007777000707h0llllll6l6ll000000ll6l6il00l00l
lhlllhh06l6ll0lllllll6l6llllllhl6l6ll000000ll6l6hh00llll6l6llllllllll6l6llllllll7070070077700707l0llllll6l6l00000000l6l6llh0l00h
hhhlhlhh6l6ll0l000lll6l6illlilhl6l6l00000000l6l6hh00illl6l6l0llll000l6l6illlilll7070070070700707h0ililll6l6l00000000l6l6hlh0hhhl
lhllllhh6l6ll0l000lll6l6llllllll6l6lll000000l6l6hh0hllll6l6l0lll0000l6l6llllllll7070077777700707l0llllll6l6l00000000l6l6lhh0llll
ihhlilhh6l6ll0l000lll6l6llllllil6l6ll0000000l6l60h0lllll6l6l0lll0000l6l6llllllll7070000000000707lhllllll6l6l00000000l6l6hlh0hlhl
lhllllil6l6ll00000lll6l6llllllll6l6ll000000ll6l60h0lllll6l6l0lll000ll6l6llllllll7070007070000707lhllllll6l6lll00000ll6l6lll0llll
ihllhlhl6l6ll0lll0lll6l6illlilll6l6ll0000llll6l6hh0lilll6l6l0ll0000ll6l6llllilll7070007777000707ihllllll6l6lllll0l0ll6l6hlh0hlhl
lhlllihl6ll6llllllll6ll6llllllll6l6l000llllll6l6lhhlllll6l6l000000lll6l6llllllll7070007007000707l0llllll6l6llllllllll6l6lhl0lhll
ililllhli6ll66666666ll6lllllllll6ll6llllllll6ll6lhhlllil6ll6llllllll6ll6llllllll7007000000007007lhllllll6ll6llllllll6ll6hlh0ilhl
llllllilll6llllllllll6lllllllllll6ll66666666ll6llhlllllll6ll66666666ll6llllllllll70077777777007llhlllllll6ll66666666ll6llll0llll
ililhlhlhlh6666666666lililllilllil6llllllllll6llihllilllil6llllllllll6llilllllllil700000000007lliillllllil6llllllllll6hlhlhhhlhl
lilllllllllllllllllllllllllllllllll6666666666llllhlllllllll6666666666llllllllllllll7777777777llllllllllllll6666666666llllilhlhll
ililllhlilhlllilllilllilllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllilllilllllllhlllhlhlhhilhl
lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllhllll
ililililhlililililllilllilllilllilllilllllllilllllllilllilllilllilllilllllllilllilllilllilllilllilllilllilllilllilllililhlhhhlhl
lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllhlill
llilllilllilllilllilllllllllllillllllllllllllllllllllllllll7770770777lllllllllllllllllllllllllllllllllllllilllilllhlllhlilhlhlhl
llllllhlllllllllllllllllllllllllllllllllllllllllllllllllll70007rr70007llllllllllllllllllllllllllllllllllllllllllllllllllllllllli
ililhlhlhlilhlililllilililllilililllilililllilililllilili70077077077007lilllilililllilililllilililllilililllililhlililhlhlhlhlhl
lllllllllll666l66l666llllllllllllll666l66l666lllllllllll7007000000007007lllllllllllllllllllllllllllllllllllllllllllllllllhlllill
hlhlllhlll6lll6006lll6illlilllilll6lll6006lll6illlilllil7070077077000707llilllillli666l66l666lilllilllillli666l66l666lhlilhlhlhl
lllllllll6ll66l66l66ll6llllllllll6ll66l66l66ll6lllllllll7070077000000707llllllllll6lll6006lll6llllllllllll6lll6006lll6llllllllli
hlilhlhl6ll6llllllll6ll6illlilll6ll6llllllll6ll6illlilll7070000777700707illlillli6ll66l66l66ll6lilllillli6ll66l66l66ll6lhlhlhlhl
llllllll6l6ll00000lll6l6llllllll6l6llll000lll6l6llllllll7070700707000707llllllll6ll6llllllll6ll6llllllll6ll6llllllll6ll6lilllill
llilllhl6l6ll000000ll6l6llilllll6l6lll00000ll6l6llilllll7070077777770707llilllll6l6ll0lll0lll6l6llilllll6l6llll00llll6l6ilhlhlhl
llllllll6l6l00000000l6l6llllllll6l6ll0000000l6l6llllllll7070777770000707llllllll6l6ll000000ll6l6llllllll6l6lll0ll0lll6l6llllllli
hlhlilhl6l6l00000000l6l6hlililll6l6ll0000000l6l6hlililll7070770707000707hlililll6l6ll000000ll6l6hlililll6l6lll0ll0lll6l6hlhlhlhl
lillllll6l6l00000000l6l6llllllll6l6ll0000000l6l6llllllll7070700707000707llllllll6l6ll000000ll6l6llllllll6l6llll0lllll6l6lilllill
ilhlliii6l6l00000000l6l6iiiiiiii6l6ll0000000l6l6iiiiiiii7007000000007007iiiiiiii6l6ll0000llll6l6iiiiiiii6l6lllll0llll6l6hlhlilhl
llllllll6l6l00000000l6l6llllllll6l6lll0l0l0ll6l6lllllllll70077777777007lllllllll6l6ll0000llll6l6llllllll6l6lllll0llll6l6llllllll
illlhlil6l6l00000000l6l6hlllilil6l6llllllllll6l6hlllililhl700000000007ilhlllilil6l6ll00000lll6l6hlllilil6l6lllll0llll6l6hlhlhlhl
llllllll6ll6llllllll6ll6llllllll6ll6llllllll6ll6lllllllllll7777777777lllllllllll6l6ll0lllllll6l6llllllll6l6lllll0llll6l6lilllhll
llhlilill6ll66666666ll6lllilllill6ll66666666ll6lllilllilllilllilllilllilllilllil6ll6llllllll6ll6llilllil6ll6llllllll6ll6ilhlhlhl
llllllllll6llllllllll6llllllllllll6llllllllll6lllllllllllllllllllllllllllllllllll6ll66666666ll6llllllllll6ll66666666ll6lllllllll
hlilhlilili6666666666lililllilllill6666666666lililllilili00000000000000lilllililil6llllllllll6ililllililil6llllllllll6ilhlhlhlhl
lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll6666666666llllllllllllll6666666666illlhlhlhlh
ililllhlilhlllhlllilllilllllllllllilllilllilllilllilllilllilllilllilllilllilllilllilllilllilllilllilllilllilllhlililllhlhlhlhlhl
lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllhlhlh
ililhlilhlilhlililllilllllllllllilllilllilllilllilllilllilllilllilllilllilllilllilllilllilllilllilllilllilllhlilhlilhlhlhlhlhlhl
lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllilllilllhll
llilllhlilhlililllilllllllllllllllilllllllilllllllilllllllilllllllilllllllilllllllilllllllilllllllilllllllilllhlilililhlilhlhlhl
lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllh
hlllhlhliiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiihlhlhlhl
l0l0h0l0i0i0l0l0i0i0l0l0i0i0l0l0i0i0l0l0i0i0l0l0i0i0l0l0i0i060l0606060l0i0i0l0l0i0i0l0l0i0i0l0l0i0i0l0l0i0i0l0l0i0i0l0l0l0l0l0l0
0l0l000l0l0606060l060l0l0l0l0l0l0l0606060l060l0l0l0l0l0l0l0l0l00060l060l0l0l0l0l0l0606060l060l0l0l0l0l0l0l0606060l060l0l0l0l0l0l
l0l0h0l0l060l06000l0l0l0l0l0l0l0l060l06000l0l0l0l0l0l0l0l0l060l06060l060l0l0l0l0l060l06000l0l0l0l0l0l0l0l060l06000l0l0l0l0l0l0l0
0l0h0h0l060l06060l060l0l0l0l0l0l060l06060l060l0l0l0l0l0l0l060l0l0l0l0l060l0l0l0l060l06060l060l0l0l0l0l0l060l06060l060l0l0l0l0h0l
l0l0h0l060l0l0l0l0l060l0l0l0l0l060l0l0l0l0l060l0l0l0l0l06060l0l0l0l0l0l0l0l0l0l060l0l0l0l0l060l0l0l0l0l060l0l0l0l0l060l0l0l0l0l0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000007707070777077707770000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000070007070707070707770000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000077707070777077007070000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000707770707070707070000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000077007770707070707070000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000rrr0rrr0rrr00rr0rrr0000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000r0r0r000r0r0r0000r00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000rr00rr00rrr0rrr00r00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000r0r0r000r0r000r00r00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000rrr0rrr0r0r0rr000r00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000770000700000000000007770007077700000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000070000777700000000000070070000700000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000070000777000000000007770070077700000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000070007777000070000007000070070000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000777000007000700000007770700077700000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000rr0rrr0rr000r00rrr00000rrr0r0000rr00rr0r0r000000rr0r0r00rr00rr0rrr00rr00000000000000000000000000000
0000000000000000000000000000r000r0r0r0r0r0000r000000r0r0r000r0r0r000r0r00000r000r0r0r0r0r0000r00r0000000000000000000000000000000
0000000000000000000000000000r000rrr0r0r000000r000000rr00r000r0r0r000rr000000r000rrr0r0r0rrr00r00rrr00000000000000000000000000000
0000000000000000000000000000r000r0r0r0r000000r000000r0r0r000r0r0r000r0r00000r0r0r0r0r0r000r00r0000r00000000000000000000000000000
00000000000000000000000000000rr0r0r0r0r000000r000000rrr0rrr0rr000rr0r0r00000rrr0r0r0rr00rr000r00rr000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007770777070700000077070707770770007707770000077700770000077007770777070700000077070707770777077700000000000000000
00000000000000007000707000700000700070707070707070007000000007007070000070707070707070700000700070707070707077700000000000000000
00000000000000007770707007000000700077707770707070007700000007007070000070707700777070700000777070707770770070700000000000000000
00000000000000000070707070000000700070707070707070007000000007007070000070707070707077700000007077707070707070700000000000000000
00000000000000007770777070700000077070707070707007707770000007007700000077707070707077700000770077707070707070700000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
0000676755676767676767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000676767677683676767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000067676467677a766767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000677867876767676767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000676767676467677c67000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000675e674f6767677a67000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000676767676767856767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
11240000155651c5651d565155651c5651d565155651a5651c565155651a5651c565155651a565185651a565155651c5651d565155651c5651d565155651a5651c565155651a5651c565155651a565185651a565
152400000000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050901509025090350904509055090650907509075
152400000907509075000000907509075000050907509075000000907509075090750707507075070750000505075050750000505075050750000505075050750000505075050750507507075070750707500005
c92400000953209532095320953209532095320953209532095320953209532095320953209532095320953209532095320953209532095320953209532095320953209532095320953209532095320953209532
c92400001053210532105321053210532105321053210532105321053210532105321053210532105321053210532105321053210532105321053210532105321153210532115321053211532105321153210532
c92400000253202532025320253202532025320253202532025320253202532025320253202532025320253202532025320253202532025320253202532025320253204532055320453205532075320553207532
152400000507505075000000507505075000000507505075000000507505075050750407504075040750407502075020750000002075020750000002075020750000002075020750207507075070750707507075
012400000c0430c043156430c0430c04300603156430c0430c0430c043156430c043006030c04315643156430c04300603156430c0430c0430060315643006030c0430060315643006030c043156431564315643
31240020307402f740307402f7402d7402f7402d7402d7402d7402d7402d7402d740297402b7402974028740267402674026740267402674026740267402674026740287402674028740297402b7402d7402f740
3124000030740307402f740307402f7402f7402d7402f740000002d7402b7402d7402b7402b740297402b74000000297402874029740287402874026740287402674026740247402674024740267402474026740
012400002474024740247402474024742247422474224742247422474224742247422474224742247422474218742187421874218742187321873218732187321872218722187221872218712187121871218712
5d1e000000345003450034500345013450030500345003450034500345013450030500345003450034500345013450030500345003450034500345013450030500345003450034500345013450c3450c3450c345
011e0000180321803218032180321f0321f0321f0321f0321e0321e0321e0321e0321e0321e0321e0321e032180321803218032180321b0321b0321b0321b0321a0321a0321a0321a0321a0321a0321a0321a032
5d1e000000345003450034500345013452142500345003450034500345013452142500345003450034500345013452142500345003450034500345013452142500345003450034500345013450c3450c3450c345
991e00000c33300422004220c3331a33307422074220c3331a3331a333064220c3331a3330642206422064220c333264252142500422034220c33321425034221a3331a333024221a33321425024220242202422
911e000000345003450034500345013451842500345003450034500345013451e42500345003450034500345013451842500345003450034500345013450134500345003450034500345013450c3450c3450c345
911e00000c333184251e4250c3331a3330c3331e4250c3331a3331a333184250c3331a3331a3331a3331e4250c3331e4251e4250c3331a3330c333013450c3331a3331a3331e4251a333184251a3331e42518425
5c1e00000004500300003000000000045003000000000000000450030000300000000004500300003000030000045003000030000000000450030000000000000004500300003000000000045003000030000300
012100000711207122071320711207122071320711207122071320711207122071320711207122071320711207122071320711207122071320711207122071320711207122071320711207122071320711207122
012100000c0330703202032000320c0330003202032000320c0330203203032020320c0330203203032020320c0330003202032000320c0330003202032000320c0330303205032050320c033030320703207032
0121000013012180221a0321b0421a0321302218012130220e032130420e0320c0220f0120e0220c0321304213012180221a0321b0421a0321302218012130220e032130420e0320c0220e012130220e0320c042
012100000711207122071320711207122071320711207122051320511205122051320511205122051320511204122041320411204122041320411204122041320511205122051320511205122051320511205122
0121000013012180221a0321b0421a0321302218012130220e032130420e0320c0220f0120e0220c0321304213032180221a0121b0221a0321304218032180221a0121f022240322604227032260222401226022
0121000007012080220c0320e042130520e0420c0320802207012080220c032070420805213042180321b0221a0121f02225032240421f052240422503226022260122b0222603227042260522b0423003231022
012100000c0430c04307132071120c0430713207112071220c0430711207122071320c0430712207132071120c0430c04307112071220c0430711207122071320c0430712207132071120c043071320711207122
012200000c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c0430c04300000000000c0430000000000000000c0430000000000000000c043000000000000000
000100032a370212701c7601d34020340233400654029340075402534008540075402034007440263400744000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002f650236501d6501c6502b6503f6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000131501a150203500e25030650246501f6501c6501865015650116500e6500b650096501250011500376003a6000760006600000000000000000000000000000000000000000000000000000000000000
0001000028070330702c0602906032050270502705030050300402c040250402d0402204024040320402c03029030310302c020270202b0202f01028010210102a010290102c0003200000000000000000000000
000400000b3700b3700b3700437004370043702700030000171002c000250002d0001710024000171002c00017100310001710017100171002f000171002100017100171001710011100111000f1000f1000f100
00030000013100332003320043300433005330053300634007340073400734008340093500a3500c3500f3601136014360193601f360327703275024740247202471000000000000000000000000000000000000
000300001f0502705030050360502c050090500405000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000000003715034150361502f1503b1503215033300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100002d070300702e060260601c0502e050190501c050240402604017040170401b040260401d04013030140301b0301e02018020190201f0101f0101a0101a0101f0101c010160101b010000000000000000
000100001007011070130602606015050170501b0501d05021040270402a0402e040360403b0401d04013030140001b0001e00018000190001f000360502a050250501b050120100e0501b000000000000000000
__music__
00 00030444
00 00050444
00 00014344
01 00024344
00 00024344
00 00064344
00 00064344
00 00020744
00 00020744
00 00060744
00 00060744
00 00030444
00 00050444
00 00020708
00 00020709
00 0006070a
02 00060741
01 0b424344
00 0b424344
00 0b0c4344
00 0b0c4344
00 0d0e4344
00 0d0e4344
00 0f104344
00 0f104344
00 0c104344
00 0c104344
00 110c4344
00 110c4344
02 114c4344
01 19424344
00 12134344
00 12134344
00 14134344
00 16134344
00 12174344
00 12174344
00 18174344
00 18174344
00 12134344
00 12134344
00 14174344
00 16174344
00 14154344
00 16154344
00 14134344
00 16134344
00 56134344
00 56134344
02 19424344


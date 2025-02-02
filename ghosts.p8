pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
health_x=0
health_tx=0
summary_y=128
preview_c_wrapper=nil
no_wait=false
disable_tutorials=false
function ssfx(n,c)
	--sfx(9, 1)
	sfx(n,c or 3)
end

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

function _init()
	parens8[[
		(cartdata "demons_of_the_great_beyond")
		(palt 14 1)
		(palt 0 nil)
		(set player (table))
		(set resumed (load_progress))
		(when (not resumed)
			(seq
				(set current_enemy_index 1)
				(set seed (rnd 1000))
			)
		)
		(set music_disabled (== (peek (+ 0x5e00 73)) 1))
		(when (not music_disabled)
			(music 17 4000)
		)
		(set new_game_plus nil)
		(when (>= current_enemy_index (rawlen enemies))
			(set new_game_plus 1)
		)
		(when (not new_game_plus)
			(set player.hp 16)
		)
		(start_new_game current_enemy_index)
		(set c_game_logic (cocreate game_logic))
		(set message_circles_front (table))
		(set message_circles_back (table))
		(for (i 1 45)
			(seq
				(add message_circles_front (table
					(x (+ -10 (rnd 148))) 
					(y 
						(+ 78 (* 16 (- (rnd) 0.5)))
					)
				))
				(add message_circles_back (table
					
					(x (+ -10 (rnd 148))) (y 
						(+ 78 (* 16 (- (rnd) 0.5)))
					)
				))
			)	
		)
		
	]]
end
function _draw_game()
	camera()
	local t=player.damaged_at and time()-player.damaged_at
	if(t and t<0.5)camera(rnd(5),rnd(3))
	t=opp.damaged_at and time()-opp.damaged_at
	if(t and t<0.5)camera(rnd(5),rnd(3))
	draw_rows(player.rows)
	draw_rows(opp.rows, true)
	draw_player_hand()
	opp.h_manager:draw()
	if player.v_hp then
		draw_health(player,100)
		draw_health(opp,0)
	end
	draw_hit_spark()
	if(game_over) then 
		rectfill(
			0,60,
			128,68,
			8
		)
		print(
			game_over,
			64-#game_over*2,
			62,
			7
		)
	end	

	local y = nil
	local t=time()-game_started_at
	t/=3
	if t < 2.5 then
		y = 64*((t-1)*(t-1)*(t-1)+0.8)+10
	else  
		y= 188-2*summary_y
	end
	if y and current_enemy then
		draw_enemy(current_enemy, y+10, y-32)
		rectfill(0,y,128,8+y,1)
		print("opponent "..tostr((current_enemy_index - 1) % #enemies + 1).."/"..tostr(#enemies)..": the "..current_enemy.name, 2, y+2, 7)
		
	end
	local clear_t = time()-message_cleared_at
	clear_t *= 1.5
	if(message_text or clear_t < 1 )then
		local y=70
		local tut_t = time()-message_at
		tut_t *= 1.5
		local t = message_text and  tut_t or (1-clear_t)
		t=min(t,1)
		for i, c in ipairs(message_circles_back) do
			local r=t*12 + 1
			r+=2*sin(time()/3 + i*0.1)
			ovalfill(c.x-r,c.y-r,c.x+r,c.y+r,13)
		end
		for i, c in ipairs(message_circles_front) do
			local r=t*(t-1)*-4*12 + 1
			ovalfill(c.x-r,c.y-r,c.x+r,c.y+r,13)
		end
		for i, c in ipairs(message_circles_back) do
			local r=t*12 
			r+=2*sin(time()/3+ i*0.1)
			ovalfill(c.x-r,c.y-r,c.x+r,c.y+r,0)
		end
		if t>0.5 and message_text then
			print(message_text,2,y,7)
			color(5)
			print("❎ to continue")
		end
		for i, c in ipairs(message_circles_front) do
			local r=t*(t-1)*-4*12 
			if r>1 then
				ovalfill(c.x-r,c.y-r,c.x+r,c.y+r,0)
			end
		end
	end
end

function _update_game()
	update_rows()
	health_tx=((player_input!="hand" or summary_y<100) and -14 or 2)
	summary_y=lerp(summary_y, player.h_manager.y_base+17, .07)
	if player.damaged_at and time()-player.damaged_at<1
	or health_drawer_at and time()-health_drawer_at<2
	or opp.damaged_at and time()-opp.damaged_at<1
	or game_over
	then
		health_tx=2
	end
	
	health_x=lerp(health_x,health_tx,.2)
	if player.v_hp then
		player.v_hp=lerp(player.v_hp, player.hp,.3)
		if abs(player.v_hp-player.hp)<.1 then
			player.v_hp=player.hp
		end
		opp.v_hp=lerp(opp.v_hp, opp.hp,.3)
		if abs(opp.v_hp-opp.hp)<.1 then
			opp.v_hp=opp.hp
		end
	end

	update_hands(message_text!=nil)
	if message_text  then
		local t= time()-message_at
		if btnp(❎)and t>0.8 then
			message_ok()
		end
		return
	end

	player.h_manager.y_base = (btn(⬇️) and player_input=="hand") and 60 or 89
	
	if time() > 4 and new_game_plus then
		message("in new game plus you no longer\nheal automatically between rounds")
	end

	if player_input == "hand" then
		local playable_cards = {}
		for i, hc in ipairs(player.h_manager.cards) do
			if hc.c ~= "endturn" and hc.c.cost <= player.mana then
				add(playable_cards, hc)
			end
		end
		if #playable_cards == 0 and time() > 2 then
			tutorial("you don't have enough mana to\nsummon any demons, end the turn")
		elseif time() > 10 and preview_c_wrapper and preview_c_wrapper.c.type == "ghost" then
			tutorial("hold ⬇️ to view detailed\ncard info") 
		end
		if foreach_rc(function() return 1 end) >= 4 then 
			tutorial("press ⬆️ to view the demons on\nthe board") 
		end
	end
	if player_input == "view_board" and current_enemy_index != 1 then
		tutorial("hold ❎ to view the demons'\nattack and health") 
	end
	if current_enemy_index >= 3 then
		tutorial("you can view your deck from\nthe pause menu at any time") 
	end
	
	local status=costatus(c_game_logic)
	if(c_game_logic and status!="dead") then
		local _, err = coresume(c_game_logic)
  		status=costatus(c_game_logic)
  if status=="dead" then
  	local trace=trace(c_game_logic)
  	if(trace and err)then
  		log(err..": "..trace)
	  	cls(0)
	  	cursor()
	  	stop(err..": "..trace)
	elseif(err) then
		log("no trace: "..err)
	end
  end
	end
	if hit_frame then
		hit_frame+=1
	end
end
function draw_sprite(s,x,y)
	spr(s+(time()%1>0.5 and 1 or 0),x+4,y+4,1,1)
end
function draw_deinterlaced(x,y,sx,sy,primary)
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

	sspr(sx,sy,32,32,x,y)
	rpal()
end
function draw_enemy(e,x,y)
	draw_deinterlaced(x,y,e.facex,e.facey,e.facealt!=1)
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
	else if c=="heal 3" then
		spr(66,x,y,2,2)
		spr(98,x+4,y+4)
		return
	end
	end
	end
	local col  = (actor==nil or actor==opp or actor.mana>=c.cost) and 7 or 6
	pal(7,col)
	pal(8,actor==opp and 5 or types[c.type])
	spr(64,x,y,2,2)
	if(actor!=opp)draw_sprite(c.s,x,y)
	
	pal(7,7)
	pal(8,8)
end


function draw_player_hand()
	player.h_manager:draw()
	local s_i=
		(player_input == "hand") 
		and player.h_manager.selected_index
		or nil

	local s_hc=s_i and player.h_manager.cards[s_i]

	if preview_c_wrapper and preview_c_wrapper.c.name then
		draw_summary(preview_c_wrapper,summary_y, summary_y < 95)
	end
end

function draw_summary(c_or_c_wrapper,y,full)
	local c=c_or_c_wrapper.c or c_or_c_wrapper
	local rc= c_or_c_wrapper.hp and c_or_c_wrapper or nil
	local str = c.type
	mark_card_seen(c)
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
	end
end

shown_messages={}
message_stack={}
message_at=0
message_cleared_at=0
function tutorial(key, string)
	string = string or key
	if disable_tutorials then
		return
	end
	message(key, string)
end
function message(key, string)
	string = string or key
	if not shown_messages[key] then
		shown_messages[key]=true

		if message_text == nil then
			message_at=time()
			message_text=string
		else
			add(message_stack,string)
		end
	end
end
function message_ok()
	if #message_stack > 0 then
		message_text=deli(message_stack,1)
	else
		message_text=nil
		message_cleared_at=time()
	end
end

function move_view_board_cursor(x, y)
	preview_changed_at = time()
	if abs(y) > 0 then
		local actor=sgn(preview_i)==1 and player or opp
		local other_actor=actor==opp and player or opp
	
		local cx,cy=preview_i, row_i
		
		while true do
			cy+=y
			if abs(cy)>3 then
				player_input="hand"
				break
			end
			if cy<0 then
				break
			end
			local row=actor.rows[cy]
			if row and #row > 0 and abs(cx)>#row then
				cx=sgn(cx)*#row
			end
			if row and row[abs(cx)] then
				row_i=cy
				preview_i=cx
				break
			end
		end
	else
		local actor=sgn(preview_i)==1 and player or opp
		local other_actor=actor==opp and player or opp
	
		local row=actor.rows[row_i]
		local o_row=other_actor.rows[row_i]
		if abs(preview_i+x*sgn(row_i)) > 0 then
			preview_i+=x
			if row and abs(preview_i) > #row then
				if #o_row>0 then
					preview_i=-#o_row*sgn(preview_i)
				else
					preview_i-=x*sgn(preview_i)
					if row_i==3 then
						row_i+=1
					end
					for j=0,2 do
					
						local i=(j+row_i)%3+1
						local l = #other_actor.rows[i]
						if l > 0 then
							preview_i=-l*sgn(preview_i)
							row_i=i
							break
						end
					end
				end
			end
		end
	end
	local actor=sgn(preview_i)==1 and player or opp
	local row=actor.rows[row_i]
	local preview=row and row[abs(preview_i)]
	preview_c_wrapper=preview
end

function update_hands(disable_input)
	player.h_manager.enabled=player_input=="hand"
	if player_input == "hand" then
		preview_i=player.h_manager.selected_index
		local hc = player.h_manager.cards[preview_i]
		preview_c_wrapper=hc
	end
	player.h_manager:update(disable_input)
	opp.h_manager:update(disable_input)
	if player_input=="view_board" then
		if btnp(➡️) then 
			move_view_board_cursor(1,0)
		end
		if btnp(⬅️) then
			move_view_board_cursor(-1,0)
		end
		if btnp(⬇️) then
			move_view_board_cursor(0,1)
		end
		if btnp(⬆️) then
			move_view_board_cursor(0,-1)
		end
	end
end

function has_board_ability(c)
	return c.on_void or c.double_abilites_for or c.double_damage_to_opponent or c.can_attack or c.can_defend or c.on_kill
end

function draw_rows(rows,flip)
	for i,row in ipairs(rows) do
		if not flip and player_input=="rows" then
			if row_i == i then
				spr(32,10*(1+#row),35+14*i,1,1,true)
			elseif row_i == -i then
				spr(32,0,35+14*i)
			end
		end
		
		for j,rc in ipairs(row) do
			local x,y=0+10*j,35+14*i

			if rc.attacking_at then
				local t=time()-rc.attacking_at
				local slide_t=
					clamp(t/.4,0,1)
					
				if t>1.1 then
					slide_t=clamp((t-1.1)/.4,0,1)
					x=lerp(60,x,ease(slide_t))

				else
					x=lerp(x,60,ease(slide_t))
				end
				local strike_t=
					clamp((t-.5)/.5,0,1)
				if strike_t<.5 then
					x-=strike_t*(strike_t-.5)*rc.attacking_x
					y+=strike_t*(strike_t-.5)*rc.attacking_y
				end
			end
			
			if rc.damaged_at then
				local t=time() - rc.damaged_at
				if t < .6 then
					x+=rnd()*3-1
				end
			end
			if rc.possessed_at then
				local t=time() - rc.possessed_at
				if t < .5 then
					y+=t*(t-.5)*70
				end
			end
			if(flip)x=128-x
			
			if rc.hp < rc.c.def and not ( btn(❎) and player_input=="view_board") then
				line(x,y-2,x+7,y-2,8)	
				if rc.hp>0 then
					line(x,y-2,x+7*rc.hp/rc.c.def,y-2,7)	
				end
			end
					
			if player_input=="view_board" and not btn(❎) then
				if row_i == i then
					if preview_i*(flip and -1 or 1)==j then
						spr(16,x,y-8)
						print_centered(rc.c.name,x+4,y-12)
					end
				end
			end
			
			local t=rc.summoned_at and time()-rc.summoned_at
			
			if t and t < 10/14 then 
				local pw=100-140*t
				local ph=pw*.6
				draw_pentagram(
					x-pw+4,y-ph+8,
					x+pw+4,y+ph+8,
					t*t,8)
			else
				rc.summoned_at=nil
			end
			if t==nil or t > .6 then
				if btn(❎) and player_input=="view_board" then
					local col = types[rc.c.type]
					if has_board_ability(rc.c) then
						col=time()%1>.5 and 7 or col
					end
					
					local x = print(rc.c.atk <= 9 and rc.c.atk or "+",x,y,col)
					x=print("/",x-1,y+2,col)
					x = print(rc.hp <= 9 and rc.hp or "+",x-1,y+4, rc.hp < rc.c.def and 8 or col)
					
				else
					palt(0,true)
					if t and t < .8 then
						pal(7,8)
					end
					local idle=time()%1>.5 and 1 or 0
					if (rc.c.type=="object" and not rc.possessed) 
					or (rc.c.can_attack and not rc.c.can_attack(rc)) 
					or rc.frozen then
						idle=0
					end
					pal(7,0)
					spr(rc.c.s+idle,x,y+1,1,1,flip)
					spr(rc.c.s+idle,x,y-1,1,1,flip)
					spr(rc.c.s+idle,x+1,y,1,1,flip)
					spr(rc.c.s+idle,x-1,y,1,1,flip)
					pal(7,rc.frozen and 12 or 7)
					spr(rc.c.s+idle,x,y,1,1,flip)
					palt(0,false)
					pal(7,7)
				end
			end
			if t and t > 2 then
				rc.summoned_at=nil
			end
			if rc.ability_at then
				local t=time()-rc.ability_at
				if t<.5 then
						local r=t*20
						oval(x-r+4,y-r+4,x+r+4,y+r+4,7)
				end
			end
		end
	end
end

function update_rows()
	if player_input=="rows" then
		local r_sng,i=sgn(row_i),abs(row_i)
		if(btnp(⬆️)) i-=1
		if(btnp(⬇️)) i+=1
		if(btnp(➡️) or btnp(⬅️)) r_sng*=-1
		if(i < 1) i = 3
		if(i > 3) i = 1
		row_i = r_sng*i
	end
end
function draw_bar(x, y, p, primary_color, secondary_color, flash_condition, flash_duration, flash_frequency)
 local t = flash_condition and time() - flash_condition
 local c = (t and t < flash_duration) and primary_color or secondary_color

 ovalfill(x, y, x + 20, y + 20, 0)
 oval(x, y, x + 20, y + 20, secondary_color)
 clip(0, y + (1 - p) * 20, 128, 128)
 ovalfill(x + 3, y + 3, x + 17, y + 17, primary_color)
 clip(0, 0, 128, 128)
 ovalfill(x + 5, y + 5, x + 8, y + 8, secondary_color)
 ovalfill(x + 10, y + 10, x + 15, y + 15, secondary_color)

 if (t and t < .6) then
  x += sin(t * 10)
 end
end

function print_centered(text, x, y, color, w)
	local w = w or 4* #tostr(text)
	local tx= x- w/2
	local mx=128-4*#tostr(text)
	if tx<0 then
		tx=0
	elseif tx>mx then
		tx=mx
	end
	rectfill(-2+tx, y-1, x +w/2, y+5, 0)
	print(text, tx, y, color or 7)
end

function draw_health(actor, y)
 local hp, mana, used_mana = actor.v_hp, actor.mana, actor.used_mana
 local health_x = health_x
	if actor==opp then
		health_x=106-health_x
	end
 -- draw health bar
 local p = hp / actor.max_hp
 draw_bar(health_x, y, p, 8, 7, actor.damaged_at, 1/30, nil)
 print_centered(flr(hp), health_x + 10, y + 22, 8)

 -- draw mana bar
 p = mana / 7
 local x = 128 - health_x - 20
 draw_bar(x, y, p, 12, 7, actor.mana_flash_at, 0.6, 10)
 local str = tostr(mana) .. "✽/" .. tostr(mana + used_mana)..'✽'
 local color = actor.mana_flash_at and time() - actor.mana_flash_at < 0.6 and 8 or 12
 print_centered(str, x+10, y + 22, color, 30)
end
-->8
--util
function draw_pentagram(x1, y1, x2, y2, angle, col)
 oval(x1, y1, x2, y2, col)
 local cx, cy, w, h = (x1 + x2) / 2, (y1 + y2) / 2, (x2 - x1) / 2, (y2 - y1) / 2
 local step = 2 / 5
 for i = 0, 4 do
  local a_a, a_b = angle + step * i, angle + step * (i - 1)
  local x_a, y_a = sin(a_a) * w + cx, cos(a_a) * h + cy
  local x_b, y_b = sin(a_b) * w + cx, cos(a_b) * h + cy
  line(x_a, y_a, x_b, y_b, col)
 end
end
function imut_add(list,value)
	local result={}
	for v in all(list) do
		add(result, v)
	end
	add(result, value)
	return result
end
function clamp(a,b,c)
	if(a>c)return c
	if(a<b)return b
	return a
end
function lerp(from,to,p)
	return from*(1-p)+to*p
end
function ease(t,p)
	p=p or 3
	if(t<.5)return t^p*2
	t=1-t
	return 1-t^p*p*2
end
function wait(s)
	while message_text != nil do
		yield()
	end
	if no_wait then
		if rnd() < 0.25 then 
			yield()
		end
		return
	end
	for j=0,30*s do
		yield()
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
deck_scene={
  init=function(self)
	self.cards = player.og_deck 
    self.i=1
	self.h_manager = create_hand_manager({
		cards=self.cards,
		spacing=32,
		height=300,
		y_base=40,
		on_move=function()
			preview_changed_at = time()
		end,
	})
	self.removed_card = nil
	self.removed_card_at = nil
  end,

  update=function(self)
	if not self.removed_card_at then
		self.h_manager:update()
		if btnp(🅾️) then
		pop_scene()
		end
		if self.is_removing and btnp(❎) then
			self.is_removing = false
			del(player.og_deck, self.h_manager:get_card())
			ssfx(43)
			self.h_manager.enabled=false
			self.removed_card = self.h_manager:get_card()
			self.removed_card_at = time()
		end
	else
		self.h_manager:get_hc().dy = self.h_manager:get_hc().dy or 0
		self.h_manager:get_hc().dy -= 1
		self.h_manager:get_hc().y += self.h_manager:get_hc().dy
		if time() - self.removed_card_at > 1 then
			start_new_game(current_enemy_index + 1)
			c_game_logic = cocreate(game_logic)
			pop_scene() -- back to rewards
			pop_scene() -- back to game
		end
	end
  end,

  	draw=function(self)
		self.h_manager:draw()
		draw_summary(self.h_manager:get_card(), 64, true)
		print_centered("view deck",64,10)
		print("press 🅾️ to go back", 2, 120, 6)
		if self.is_removing then
			print("press ❎ to remove", 2, 110, 6)
		end
		print(self.h_manager.selected_index.."/"..#self.cards, 2, 2, 7)
	end
}
menuitem(1, "view deck", function() push_scene(deck_scene) end)
menuitem(2, "title screen", function() load("#demons_wrapper") end)
menuitem(3, "toggle music", function()
	music_disabled = not music_disabled
	poke(0x5e00+73, music_disabled and 1 or 0)
	if music_disabled then
		music(-1, 500)
	else
		music(17, 2000)
	end
end)

-->8
--scenes
game_scene={
	draw=_draw_game,
	update=_update_game
}
scenes={
} -- scene stack
current_scene=nil

function push_scene(scene)
	if current_scene==scene then return end
 add(scenes,scene)
 current_scene=scene
 if scene.init then scene:init() end
end

function pop_scene()
 del(scenes,current_scene)
 current_scene=scenes[#scenes]
 if current_scene.resume then 
  current_scene:resume()
 end
end

-- override pico-8 callbacks 
function _update()
 if current_scene then
  current_scene:update()
 end
end

function _draw()
	cls()
	memcpy(0x6000,0x8000,128*128/2)
 if current_scene then
  current_scene:draw()
 end
end

push_scene(game_scene)
-->8
--game
function gl_new_game()
	for i=1,4 do
		yield()
		gl_draw_card(player)
		gl_draw_card(opp)
	end
	player.h_manager:add_to_hand("endturn")
end
function map_to_cards(ids)
	local result={}
	for id in all(ids) do
		add(result, cards[id])
	end
	return result
end

function new_player_deck()
	local opts={}
	for c in all(cards) do
		for i = 1, c.start_count or 0 do
			add(opts, c)
		end
	end
	local len = rnd({-1,0,0,1,2}) + 12
	local result={}
	for i=1,len do
		add(result, rnd(opts))
	end
	return result
end

function start_new_game(index)
	current_enemy_index = index
	current_enemy = enemies[(index-1) % #enemies + 1]
	srand(seed)
	save_progress()
	game_started_at = time()
player={
	hand={},
	rows={},
	og_deck=player and player.og_deck or new_player_deck(),
	hp=new_game_plus and player.hp or 16,
	max_hp=16,
	pick_card=function()
			player_input="hand"
			yield()
			while true do
				if btnp(❎) and player_input=="hand" then
					local c=player.h_manager:get_card()
					if c!="endturn" and c.cost > player.mana then
						ssfx(38)
						player.mana_flash_at=time()
					else
						player_input=nil
						return c
					end
				end
				yield()
			end
	end,
	select_row=function()
		player_input="rows"
		row_i=-1
		yield()
		while true do
			if player.rows[abs(row_i)] and #player.rows[abs(row_i)]>=1 then
				tutorial("demons can be summoned at the\n front or back of a row")
			end
			if btnp(🅾️) then
				return "back"
			end
			if btnp(❎) then
				if #player.rows[abs(row_i)]>=5 then
					ssfx(38)
				else
					player_input=nil
					return row_i
				end
			end
			yield()
		end
	end
}
opp={
	hand={},
	rows={},
	og_deck=map_to_cards(current_enemy.deck),
	pick_card=function(self)
			wait(.3)
			local value,opts=knapsack(opp, opp.h_manager.cards, opp.mana)
			return rnd(opts)
	end,
	select_row=ai_select_row
}
	player.h_manager = create_hand_manager({
		cards={},
		on_move=function()
			preview_changed_at = time()
		end,
		on_up=function()
			player_input="view_board"
			preview_i=1
			row_i=4
			move_view_board_cursor(0,-1)
			if preview_c_wrapper == nil then
				preview_i=-1
				row_i=4
				move_view_board_cursor(0,-1)
				if preview_c_wrapper == nil then
					player_input="hand"
				end
			end
		end,
		actor=player
	})
	opp.h_manager = create_hand_manager({
		cards={},
		enabled=false,
		inverted=true,
		actor=opp,
		y_base=12
	})
	player.rows={{},{},{}}
	opp.rows={{},{},{}}

	opp.hp=ceil(current_enemy.max_hp * (new_game_plus and 1.5 or 1))
	opp.max_hp=opp.hp
	player.v_hp=player.hp
	opp.v_hp=opp.hp
	opp.mana=0
	player.mana=0
	opp.used_mana=0
	player.used_mana=0
	player.turn_1=true
	player.deck = shallow_copy(player.og_deck)
	opp.deck = shallow_copy(opp.og_deck)
	game_over=nil

	
	-- --DEBUGGING
	-- player.pick_card = function(self)
	-- 	wait(.3)
	-- 	local value,opts=knapsack(player, player.h_manager.cards, player.mana)
	-- 	return rnd(opts)
	-- end
	-- player.select_row=ai_select_row
	-- player.hp=200
	-- opp.hp=200
	-- player.deck = shallow_copy(cards)
	-- opp.deck = shallow_copy(cards)
	-- ----

end

function shallow_copy(dict)
	local result={}
	for k,v in pairs(dict) do
		result[k]=v
	end
	return result
end

function gl_draw_card(actor)
	ssfx(35)
	if #actor.deck==0 then
		actor.h_manager:add_to_hand(void)
		return
	end
	local c = rnd(actor.deck)
	del(actor.deck, c)
	actor.h_manager:add_to_hand(c)
end

function gl_steal_card(actor)
	local target = actor==player and opp or player
	local valid_cards = {}
	for hc in all(target.h_manager.cards) do
		if type(hc.c) != "string" then
			add(valid_cards, hc)
		end
	end
	if #valid_cards > 0 then
		local hc = rnd(valid_cards)
		local x = hc.x
		local y = hc.y
		local c = hc.c
		target.h_manager:remove(c)
		actor.h_manager:add_to_hand(c,x,y)
		ssfx(43)
	end
end

function gl_tutor(player, predicate)
	local valid_cards = {}
	for c in all(player.deck) do
		if predicate(c) then
			add(valid_cards, c)
		end
	end
	if #valid_cards == 0 then
		ssfx(38)
	else
		local c = rnd(valid_cards)
		del(player.deck, c)
		player.h_manager:add_to_hand(c)
		ssfx(43)
	end
end

function game_logic()
	gl_new_game()
	local actor=player
	while true do
		foreach_rc(function(rc)
			if rc.frozen then
				rc.frozen -= 1
				if rc.frozen == 0 then
					rc.frozen = nil
				end
			end
		end)
		gl_draw_card(actor)

		if actor.mana+actor.used_mana<6 then 
			actor.mana+=1
		else
			tutorial("once you have 6 mana you\nwill no longer more each turn")
			tutorial("(some abilities can bypass\nthis limit)")
		end

		actor.mana+=actor.used_mana
		actor.used_mana=0
		
		while true do
			local c=actor:pick_card()
			if c == nil then
				break
			end			
			if c == "endturn" then
				break
			end	
			local row=actor:select_row(c)
			if row == nil then
				break
			end
			if row!="back" and c then
				actor.h_manager:remove(c)
				gl_summon(actor, c, row, false, false)
				check_game_end()
				if game_over then
					return
				end
			end
		end
		
		for i=1,3 do
			gl_attack(player.rows[i], opp.rows[i], actor)
			check_game_end()
			if game_over then
				return
			end
		end
		
		actor.turn_1=false
		actor = actor==player
			and opp 
			or player
	end
end

function check_game_end()
	if player.hp<=0 then
		game_over="game over"	
		clear_save()
		wait(4)
		load("#demons_wrapper")
		return true
	end
	if opp.hp<=0 then
		seed=rnd() --global, used for sync
		if current_enemy == enemies[9] then
			-- Player has defeated all enemies
			current_enemy_index+=1
			save_progress()
			game_over = "you won the game!"
			wait(4)
			load("#demons_wrapper")
			return true
		else-- Progress to next enemy
			save_progress()
			game_over = "victory!"
			wait(1)
			push_scene(reward_scene)
			return true
		end
	end
end

function get_doubler(actor, card)
    -- Check all rows for ability doublers
    for i=1,3 do
        local row = actor.rows[i]
        for _, rc in pairs(row) do
            if rc.c.double_abilites_for and rc.c.double_abilites_for(card) then
                return rc
            end
        end
    end
    return false
end

function gl_summon(actor,c,row_i, no_cost, disable_abilities)
	local row = actor.rows[abs(row_i)]
	if #row>=5 then
		return
	end

	yield()
	if not no_cost then
		actor.mana-=c.cost
		actor.used_mana+=c.cost
	end
	local rc= {
			c=c,
			hp=c.def,
			summoned_at=time()
		}
		local row = actor.rows[abs(row_i)]
	add(
		row,
		rc,
		row_i < 0 and 1 or #row+1
	)
	ssfx(39)
	wait(.8)
	if c.type=="ghost" then
		for other in all(row) do
			if other.c.type=="object" and not other.possessed then
				other.possessed=true
				other.possessed_at=time()
				ssfx(40)
				wait(.5)
			end
		end
	end
	
	if c.type=="object" then
		for other in all(row) do
			if other.c.type=="ghost" then
				rc.possessed=true
				rc.possessed_at=time()
				ssfx(40)
				wait(.5)
				break
			end
		end
	end
	local doubler = get_doubler(actor, c)
	if c.on_summon and not disable_abilities then
		as_ability(rc, actor, function()
			c.on_summon(actor, rc, row_i)
		end)
	end
	if c == void then
		foreach_rc(function(on_void_rc, on_void_rc_actor)
			if(on_void_rc_actor != actor) return
			if on_void_rc.c.on_void then
				as_ability(on_void_rc, on_void_rc_actor, function()
					on_void_rc.c.on_void(on_void_rc, on_void_rc_actor)
				end)
			end
		end)
	end
	if c.type == "object" then
		if rc.possessed then
			tutorial("this object has been possessed,\nand can now attack")
		else
			tutorial("this object cannot attack,\nuntil possessed by a ghost")
		end
	end
	check_game_end()
end


function can_attack(rc, actor)
	if not rc or (actor==player and actor.turn_1) then
		return false
	end
	if rc.frozen then
		return false
	end
 	if not rc.possessed and rc.c.type=="object" then
		return false
	end
	if rc.c.atk <= 0 then
		return false
	end
	if rc.c.can_attack and not rc.c.can_attack(rc) then
		return false
	end
	return true
end

function can_defend(rc, attacker)
	if attacker.c.type=="ghost" then
		if rc.c.type=="beast" then
			return false
		end
		if rc.c.type=="object" and not rc.possessed then
			return false
		end
	end
	if rc.c.can_defend then
		return rc.c.can_defend(rc, attacker)
	end
	return true
end

function get_defender(row, attacker)
 local result=nil
 for _, rc in pairs(row) do
	if can_defend(rc, attacker) then
    	result=rc
	end
 end
 return result
end

function gl_attack(player_row, opp_row)
	local player_atk,
		opp_atk=
		player_row[#player_row],
		opp_row[#opp_row]
	
	local any_damage=false
	for atk_rc in all{player_atk, opp_atk} do
		local actor=atk_rc==player_atk and player or opp
		local foe=actor==player and opp or player
		local foe_row=actor==player and opp_row or player_row
		if atk_rc and can_attack(atk_rc, actor) then
			local def_rc = get_defender(foe_row, atk_rc)
			local assumed_target = foe_row[#foe_row]
	
			if assumed_target != nil and def_rc != assumed_target then
				if assumed_target.c.can_defend then
					tutorial("some demons' abilities stop\nthem from blocking")
				elseif atk_rc.c.type=="ghost" and assumed_target.c.type=="beast" then
					tutorial("beasts cannot block ghosts!")
				end
				wait(0)
			end
			atk_rc.attacking_at = time()
			if def_rc then
				atk_rc.attacking_x=100
				atk_rc.attacking_y=0
			else
				atk_rc.attacking_x=100
				atk_rc.attacking_y=actor==player and 200 or -200
			end
			if not def_rc then
				health_drawer_at=time()
			end
			wait(.6)
			ssfx(36)
			if def_rc then
				def_rc.hp -= atk_rc.c.atk
				def_rc.damaged_at = time()
				ssfx(37,1)
				wait(.8)
				if def_rc.hp <= 0 and atk_rc.c.on_kill then
					def_rc.killed_by=atk_rc
				end
			else
				gl_damage_player(foe,atk_rc.c.atk)
				if  atk_rc.c.double_damage_to_opponent then
					as_ability(atk_rc, actor, function()
						atk_rc.attacking_at = time()
						wait(.6)
						gl_damage_player(foe,atk_rc.c.atk)
					end)
				end
			end
			wait(.25)
		

			any_damage=true
		end
	end		
	clear_dead()
end

function as_ability(rc, actor, fn)
	tutorial("ability", "some demons, like "..rc.c.name..", have\nspecial abilities")
	rc.ability_at=time()
	ssfx(41)
	wait(.5)
	fn()
	local doubler = get_doubler(actor, rc.c)
	if doubler then
		doubler.ability_at=time()
		ssfx(41)
		wait(.4)
		
		rc.ability_at=time()
		ssfx(41)
		wait(.5)
		fn()
	end
end

function gl_damage_player(actor, dam)
	actor.hp -= dam
	actor.damaged_at = time()
	create_hit_spark(
		actor==player and 12 or 113,
		actor==player and 110 or 12,
		dam*1.6
	)
	ssfx(36)
	wait(.8)
end	

function clear_dead()
	for i=1,3 do
 	for rc in all(opp.rows[i]) do
 		if rc.hp <= 0 then	
				del(opp.rows[i], rc)
				if rc.killed_by and rc.killed_by.c.on_kill then
					as_ability(rc.killed_by, player, function()
						rc.killed_by.c.on_kill(player, rc.killed_by, rc, i)
					end)
				end
			end
		end
 	for rc in all(player.rows[i]) do	
 	 	if rc.hp <= 0 then	
				del(player.rows[i], rc)
				if rc.killed_by and rc.killed_by.c.on_kill then
					as_ability(rc.killed_by, opp, function()
						rc.killed_by.c.on_kill(opp, rc.killed_by, rc, i)
					end)
				end
			end
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
	(deck (split "11,11,1,1,4,4,5,5,6,6,22,7,17,32,39,47,47"))
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
	(deck (split "18,18,43,43,43,7,37,44,20"))
))

(add enemies (table 
  (max_hp 25) 
  (name "artificer")
	(facex 96) (facey 96) (facealt 1)
  (deck (split "1,1,6,6,22,22,5,5,4,4,7,7,17,17,32,38,38,20,51"))
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
  (name "bones") (s 23) (atk 1) (def 2) (cost 1) (type "ghost") (start_count 2) ))
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
			(and (<= (rawlen actor.h_manager.cards) 3) (>= (rawlen actor.deck) 5))
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
		(desc "+1 mana for each ghost in hand (max 8)")
		(on_summon (fn (actor)
			(set actor.mana (+ actor.mana (foreach_hc actor (fn (hc)
				(when (== hc.c.type "ghost") (seq
					(set hc.ability_at (time))
					(ssfx 41)
					(wait 0.25)
					1
				) 0)
			))))
			(set actor.mana (min 8 actor.mana))
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
]]
function log(msg)
	printh(msg, "_ghosts.txt")
end
--[[

					]]
-->8
--ai

function check_possession(row, c)
  if c.type == "object" then
    for other_rc in all(row) do
      if other_rc.c.type=="ghost" then
        return true
      end
    end
  end
  return false
end

function get_pot_rc(row, c, owner)
  local pot_rc = {c=c, hp=c.def, possessed=check_possession(row, c)}
  return pot_rc, can_attack(pot_rc, owner)
end

function ai_select_row(self, c)
  local row_choice=nil
  local defensive, unprotected, aggressive, valid = {}, {}, {}, {}
  local inanimate=false
  for i=1,3 do
    local row = self.rows[i]
    if #row < 5 then 
      add(valid, i)
      local player_row = player.rows[i]

	  local player_atk = player_row[#player_row]
	  if not can_attack(player_atk, player) then
		  player_atk=nil
	  end
	  local pot_rc, pot_rc_can_attack  = get_pot_rc(row, c, opp)
      local opp_def = player_atk and get_defender(row, player_atk)
      local pot_opp_def = player_atk and get_defender(imut_add(row, pot_rc), player_atk)
      local player_def = pot_rc_can_attack and get_defender(player_row, pot_rc)
      if player_atk and not opp_def and pot_opp_def then
        add(unprotected,i)
      end
      if not player_def and pot_rc_can_attack then
        add(aggressive, i)
      end
      if #row == 0 then
        add(defensive, i)
      end
    end
  end
  
  -- choosing a row based on strategy
  if opp.hp > player.hp and #aggressive > 0 then
    row_choice = rnd(aggressive)
  elseif #unprotected > 0 then
    row_choice = rnd(unprotected)
  elseif #defensive > 0 then
    row_choice = rnd(defensive)
  elseif #aggressive > 0 then
    row_choice = rnd(aggressive)
  else
    return rnd(valid)
  end
  
  local row = opp.rows[abs(row_choice)]
  local old_opp_atk = row[#row]
  local pot_rc, can_pot_rc_attack = get_pot_rc(row, c, opp)
  
  if not can_pot_rc_attack then return -row_choice end -- if pot_rc can't attack, always put at back
  
  local old_opp_atk_score = (old_opp_atk and can_attack(old_opp_atk, opp)) and old_opp_atk.c.atk or 0
  if c.atk >= old_opp_atk_score then return row_choice end
  if c.def >= 8 then return -row_choice end
  
  return rnd{1, -1} * row_choice
end

function knapsack(actor, cards, mana, n)
	-- base case: no items or no remaining capacity
	n=n or #cards
	if n <= 0 or mana <= 0 then
	 return 0, {}
	end
	local c=cards[n].c
	if c == "endturn" then
		return knapsack(actor, cards, mana, n-1)
	end
	if c.cost > mana or (c.ai_will_play and not c.ai_will_play(actor))  then
	 return knapsack(actor, cards, mana, n-1)
	else
	 local value1, subset1 = knapsack(actor, cards, mana - c.cost, n-1)
	 local value2, subset2 = knapsack(actor, cards, mana, n-1)
	
		local c=cards[n].c
		local card_value =  c.cost + 0.1
	 	value1 = value1 + card_value
	
		if value1 > value2 then
			add(subset1, c)
			return value1, subset1
		else
			return value2, subset2
		end
	end
end


-->8
--hit spark & hand manager
hit_x, hit_y, hit_mag, hit_res, hit_rs = 50, 50, 0, 18, nil


function create_hit_spark(x, y, mag)
	hit_x, hit_y, hit_frame, rs, hit_mag = x, y, 0, {}, mag
	for i=0, hit_res do add(rs, i%2==0 and (rnd(1.75)+1) or .8) end
end


function draw_hit_spark()
	if not hit_frame or hit_frame>6 then 
		return 
	end
	local base_r=hit_frame
	local base_r, a, r1, r2 = hit_frame
	for i=0, hit_res do
		a, r1, r2 = i/hit_res, hit_mag*hit_frame*rs[i+1], hit_mag*hit_frame*rs[i%hit_res+2]
		fillp(hit_frame>5 
			and ░ 
			or hit_frame>3 
			and ▒ 
			or 0
		)
		line(
			hit_x+sin(a)*r1,
			hit_y+cos(a)*r1, 
			hit_x+sin(a+1/hit_res)*r2,
			hit_y+cos(a+1/hit_res)*r2,
			7
		)
		if hit_frame == 1 and rnd()<.4 then
			line(
				hit_x, 
				hit_y, 
				hit_x+sin(a)*(rnd(12)+3)*hit_mag, 
				hit_y+cos(a)*(rnd(12)+3)*hit_mag,
				7
			)
		end
	end
	fillp(0)
end

function create_hand_manager(config)
	-- config should include:
	-- cards = array of cards to display
	-- selected_index = current selected index (optional, defaults to 1)
	-- on_hc_selected = callback when a card is selected (optional)
	-- on_up = callback when up is pressed (optional)
	-- on_down = callback when down is pressed (optional)
	-- on_left = callback when left is pressed (optional)
	-- on_right = callback when right is pressed (optional)
	-- on_x = callback when x is pressed (optional)
	-- on_o = callback when o is pressed (optional)
	-- get_preview = function to get preview card info (optional)
	-- y_base = base y position for the hand (optional, defaults to 89)
	-- x_base = base x position for the hand (optional, defaults to 64)
	-- spacing = spacing between cards (optional, defaults to 18)
  
	local hand = {
	  cards = {},
	  selected_index = config.selected_index or 1,
		on_hc_selected = config.on_hc_selected,
		on_up = config.on_up,
		on_down = config.on_down,
		on_x = config.on_x,
		on_o = config.on_o,
		on_move=config.on_move,
		inverted = config.inverted,
	  get_preview = config.get_preview,
	  y_base = config.y_base or 89,
	  x_base = config.x_base or 64,
	  spacing = config.spacing or 18,
	  height= config.height or 50,
	  actor = config.actor,
	  enabled=true
	}
	if config.enabled == false then
		hand.enabled = false
	end
	function hand.get_hc(self)
		return self.cards[self.selected_index]
	end
	function hand.get_card(self)
		return self.cards[self.selected_index].c
	end

	function hand.add_to_hand(self, card,x,y)
		local index=nil
		for i=#self.cards, 1, -1 do
			if type(self.cards[i].c) == "string" then
				index=i
				break
			end
		end
		add(self.cards, {
			c = card,
			x = x or 124,
			y = y or 64
		},index)
	end

	function hand.remove(self, card)
		for i, hc in ipairs(self.cards) do
			if hc.c == card then
				del(self.cards, hc)
				break
			end
		end
	end

	
  
	function hand.update(self, disable_input)
	  -- Handle input
	  if self.enabled and not disable_input then
		  if btnp(⬅️) then
			self.selected_index -= 1
			if(self.on_move) self.on_move()
		  end
		  if  btnp(➡️) then
			self.selected_index += 1
			if(self.on_move) self.on_move()
		  end
		  if self.on_up and btnp(⬆️) then
			self.on_up(self)
		  end
		  if self.on_down and btnp(⬇️) then
			self.on_down(self)
		  end
		  if self.on_x and btnp(❎) then
			self.on_x(self.cards[self.selected_index].c)
		  end
		  if self.on_o and btnp(🅾️) then
			self.on_o()
		  end
	  
		  if self.selected_index < 1 then
			self.selected_index = #self.cards
		  end
		  if self.selected_index > #self.cards then
			self.selected_index = 1
		  end
	  end
	  -- Update card positions
	  local s_i = self.enabled and self.selected_index or #self.cards/2 + .5
	  for i, hc in ipairs(self.cards) do
		local p = (i-s_i)/#self.cards
		local cx = self.x_base - self.spacing/2
		local w = self.spacing-#self.cards*.7
		w = max(8,w)
		local tx = cx+(i-s_i)*w
		local ty = self.y_base+p*p*self.height*(self.inverted and -1 or 1)
  
		hc.x = lerp(hc.x,tx,0.1)
		hc.y = lerp(hc.y,ty,0.1)
	  end
	end
  
	function hand:draw()
	  -- Draw all cards
	  for i,hc in ipairs(self.cards) do

		draw_card(hc, self.actor)
	  end
	  local selected_card = self.cards[self.selected_index]
	  if selected_card then
		draw_card(selected_card, self.actor)
	  end
  
	  -- Draw selection cursor
	  local s_hc = self.enabled and self.cards[self.selected_index]
	  if s_hc then
		spr(16,s_hc.x+5,s_hc.y-7)
		
		-- Draw card name
		local name = type(s_hc.c) == 'string' and s_hc.c or s_hc.c.name
		print_centered(name,s_hc.x+8,s_hc.y-12,7)
	  end
	end
  -- Initialize cards with positions
	for i, card in ipairs(config.cards) do
		hand:add_to_hand(card)
	end
	return hand
  end

-->8
reward_scene = {
  init=function(self)
    self.rewards = {}
	reward_scene_at = time()
    local available = {}
    for i=1,#cards do
      add(available, cards[i])
    end
    
    for i=1,3 do
      local card = rnd(available)
      del(available, card)
      add(self.rewards, card)
    end
	add(self.rewards, "skip")
	if(new_game_plus)add(self.rewards, "heal 3")
	
	add(self.rewards, "remove card")
    self.h_manager = create_hand_manager({
	  cards = self.rewards,
	  y_base=32,
	  on_x = function(card)
		if (time() - reward_scene_at < .6) return
		if card == "remove card" then 
			push_scene(deck_scene)
			deck_scene.is_removing = true
			return
		elseif card == "heal 3" then 
			player.hp += 3
		elseif type(card)=='table' then
			add(player.og_deck, card)
			ssfx(40)
		end
		-- start next battle
		start_new_game(current_enemy_index + 1)
		c_game_logic = cocreate(game_logic)
		pop_scene()
	  end
	})
  end,

  update = function(self)
    self.h_manager:update()
  end,

  draw = function(self)
    print("pick a reward", 16, 10, 7)
	local c = self.h_manager:get_card()
	if type(c)=="table" then
		draw_summary(c, 64, true)
	end
    self.h_manager:draw()
  end
}

function save_deck()
	if not player.og_deck then
		return
	end
	for i = 0, 32 do
		local c = player.og_deck[i+1] 
		local index = c and indexof(cards, c) or 0
		poke(0x5e00+i, index)
	end
end
function indexof(t, v)
	for i, c in ipairs(t) do
		if c == v then
			return i
		end
	end
end
function load_deck()
	player.og_deck = {}
	for i=0, 32 do
		local addr = 0x5e00 + i
		local c = peek(addr)
		if c > 0 then
			add(player.og_deck, cards[c])
		end
	end
end
function save_progress()
	save_deck()
	if current_enemy_index >=4 then
		disable_tutorials = true
	end
	poke(0x5e00+33, current_enemy_index)
	poke4(0x5e00+34, seed)
	local read_seed = peek4(0x5e00+34)
	poke(0x5e00+38, player.hp)
	poke(0x5e00+64, disable_tutorials and 1 or 0)
	-- poke(0x5e00+73) is for music
end
function load_progress()
	current_enemy_index = peek(0x5e00+33)
    seed = peek4(0x5e00+34)
	disable_tutorials = peek(0x5e00+64) == 1
	if current_enemy_index <= 1 then
		return false
	end
	load_deck()
	player.hp = peek(0x5e00+38)
	return true
end
function clear_save()
	memset(0x5e00, 0, 64) -- First quater of memory is cleared between runs
end

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
    local old_value = current & (1 << bit_position)
    local new_value = current | (1 << bit_position)

    poke(addr, new_value)
end
-->8
-- printh("id;name;type;cost;atk;def;abilities", "cards.txt",true)

-- for i,c in ipairs(cards) do
-- 	printh(i..";"
-- 	..c.name..";"
-- 	..c.type..";"
-- 	..c.cost..";"
-- 	..c.atk..";"
-- 	..c.def..";"
-- 	..(c.desc or "")
	
-- 	, "cards.txt")
-- end

-- add(cards, stone)
-- add(cards, tentacle)
-- add(cards, void)
-- function _draw()
-- 	cls()
-- 	local cols = 7
-- 	for i, c in ipairs(cards) do
-- 		local x = flr(i/cols)*15
-- 		local y = (i%cols)*15
-- 		draw_sprite(c.s, x+6, y+10)
-- 	end
-- end

__gfx__
00000000000707000000000000007770000000000000007700000000007777000077770000000000000000000770770000000000070007000070007000000000
00000000007777700007070000077777000077700000070700000077070000700700007000077700000000000770000007707700077777700077777700000000
00700700077707000077777000070770000777770000707000000707707000077000770700770700000777000007777007700000070777000070777000000000
00077000077777770777070000777777007707700007070000007070700077077000770700770700007707007007070000077770077777700077777700000000
00077000077777700777777707777770007777770770700000070700700077077070000700777700007707000777777770070700000000000000000000000000
00700700777777007777777007777700077777700077000007707000070000700700007000777700007777007777700077777777077770000077770000000000
00000000777777007777770077770000777777000707000000770000007777000077770007007070007777007707070077770000077777000777770000000000
00000000070070000700070077000000777000000000000007070000077777700777777007007070070070707007070070070700070000000000070000000000
e00000ee000700070000000000000000077007700770000070000007000077700000000000000000007000000077770000000000000777000000000000000000
0667770e000700070007000770700707777007770770007000770000000707000000077707000000007000000777777000777700007070000007770000000000
0667770e070777707007000770777707770000770000770000770000000777700700707007000000070777007777700707777770007777000070700000000000
e06770ee700707007007777070707007707007070007777000007700070070707700777707077700070777000077700777777007000707000077770000000000
ee070eee700077707007070070070707707777070007777070077770770000000070070707077700070777000700700700777007000000007007070700000000
eee0eeee777770007777777077000077707070077000770000077770007000000007700007077700077777000777077007007007070770700000700000000000
eeeeeeee777777007777770077700777700707070000000000007700000770000007000007777700070007000777700077770770000000000000000000000000
eeeeeeee070007000700070007700770000000000070007000000007000700000000000007000700000000007770000077700000007007000700007000000000
eeeeeeee077777000077700000077700000000000000700000000000000000000000000000777700000000000777777000000000000000000077770000000000
7eeeeeee077770700777070000777770007770000000700000007000000000007000000007007770007777007777777707777770007777000700007000000000
77eeeeee707777770777777007777777077777000000000000000000700007777000000007007070070077707700770077777777007070000707077000000000
777eeeee777007777077777707770770777777700007770000077700700070700000077707777770070070707700770077777777000777000070007000000000
7777eeee707007077770070707777777777077000007770000077700000077777000707000000000077777707777707777007700000777000070007000000000
666eeeee700007077070070707777777777777700707770007077700700077707000777700707000007070000077777077777077000770000070070000000000
66eeeeee707007077000770700707070777777700770777007700770700777707707777000777700007777000000707000777770007770000700700000000000
6eeeeeee777777777777777700000000707070700777777007777770777777000777770000700700070000700000000000007070007000000707000000000000
07000000000000000000000000000000007070700000000070000000007000000007000000707000000707000000000000770000000000000000000000000000
70700000000000000000000007070070000000007077770070000000007700000007700070070700070070700077000000777000077770000777700000000000
07000000000777000000000000000000070000707070000000777700707770000007770007777700007777700077700000770700770777007707770000000000
00000000007777700070000070000007000000000077070070700007777777007077770000707000000707000077070000770700707077007070770000000000
00000000007770700007777000000000007007007000000700770700777077707777777000777700000777700077070007777070707770007077770000000000
00000000007777700070000007000070000770000077770000000000770077707777707000000000007000000777707007777070770707077707000000000000
00000000000777000000000000077000000770000077770000777700770007707707007000777700000777000777707007777770077007070770707000000000
00000000000000000000000000077000000000000070070000700700077000700700007000077000000770000777777000000000007777770077777000000000
eee7770770777eeeee777777777777ee000770000007700000000000077700000007700000000070007777700007777700077000000770000000000000077000
ee700078870007eee70000000000007e007777000077770007770000777770700070070070077000070007700070007700777700007777000007700000700700
e70077077077007e7077777777777707707070000070700777777007777707700070070000700700700077700700077700707000000707000000000007777770
70070000000070077070000000000707777777077077777777770777777777700007000000700707700700000700700000777700007777000707707070700707
70700000000007077070000000000707777707777777077777777777707077700000700000070000700700000700700070000007000000000707707070700707
70700000000007077070000000000707007777777777770070707777770777700000700070007070700077700700077700770700707707070000000007777770
70700000000007077070000000000707007777000077770077077007777770700000700000007000070007700070007700777700007777000007700000700700
70700000000007077070000000000707007777000077770007770000077700000000700000007000007777700007777700700700007007000000000000077000
70700000000007077070000000000707000000000777777000000000000000000000000000000000077777000077777000700700000000007707700000000000
70700000000007077070000000000707077777707700700000000000000000000077000000077000700000700700000700070070007007000707070077077000
70700000000007077070000000000707770070007777777700070700000000000777770000777770707770700707770700777770000700700077070007070700
70700000000007077070000000000707777777777070707000707070000707007777777777777777700700700700700707700700007777700707770000770700
70070000000070077070000000000707707070707000000000777770007070700000000000000000707770700707770707700700077007000770777007077700
e70077777777007e7077777777777707700000007000000007777770007777700000770000077000707070700707070707777770077007000777077007707770
ee700000000007eee70000000000007e770707077707070770070070077777700007777000777700700000700700000777777770777777700777777007770770
eee7777777777eeeee777777777777ee777777777777777777077077770770770000000000000000077777000077777077777700777777700777777077777777
00000000000000000077000000000000000000000000000000000000070777700077770007777000070000700000000000000000000000000000000000000000
00000007000070000077000000000000000070070000000000000000777077770070700007070000077007700700007000000000000000007700000000000077
00000077000777007777770000000000770077770000700707077770000000000077770007777000007777000770077000000000770700007770007777000777
00000770007777707777770000000000777070700000777777707777000700700000000000000000007070000077770077070000070770000770077777700770
70007700000070000077000000000000077077770770707000000000000000000070070007007000707777070070700007077000770777000007077007707000
77077000000070000077007000000000007770007700777777707007777070070077700000770000070000700077770077077700770707700007700000070000
07770000000070000000077700000000777770700007000077707777777077770007000000070000000770007000000777070770700777070007000000070000
00700000007770000000007000000000770070707700707077707777777077770000700000700000077007700770077070077707000000000007000000070000
00000000000000000000000000000000000777000077700007777000000000000000000000000000007777000000000000777700000000000007070000070700
00000000000000000000000000000000070700700070000077777700077770007770000000000770077777700077770007770000000000000007777000077770
00000000000000000000000000000000700000000000007777700070777777000777077000777077777777770777777077700000000777007007070007070700
00000000000000000000000000000000700770777007700777070707777000700077707707777770777007707777777777700000007777707007777007077770
00000000000000000000000000000000770770077007700777000007770707070007777077707770777007707770077077770000077700777000000007000000
00000000000000000000000000000000000000077700000007777770770000070077777000000000777777777770077007777000077700070707770007077700
00000000000000000000000000000000070070700000070007777770077777700000000000070700077777707777777700777700077770000777777007777770
00000000000000000000000000000000007770000007770077777770777777770007070000000000777007777777777700777700007777000070707000707070
070000070000000000777000000000000007770000077700000777000000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
077000770700000707070000007770000770700000707070007070000007770000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
007777700770007707777000070700000777777007777770007777000070700000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
077077070077777000000000077770000777777007777770007707000077770000000000000000000000000000000000eeeeeeeeeeee00000000eeeeeeeeeeee
007700700770770707777707000000000777777007777700077777700077070000000000000000000000000000000000eeeeeeeeeee0700777770eeeeeeeeeee
077777700777007007700707077777070077770007777700077707700777777000000000000000000000000000000000eeeeeeeeee070777777770eeeeeeeeee
777777707777777000000000077007077077700070777000077777700777077000000000000000000000000000000000eeeeeeeee07007777700770eeeeeeeee
707000707070007007070000700070000777700007777000007777007777777700000000000000000000000000000000eeeeeeeee07077777770770eeeeeeeee
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
00000000000000000000000007070000000000707000000000077070000000000707000000000077070000000000707000000000070700000000000000000000
77000000000000000000000007070000000000707000000000077070000000000707000000000077070000000000707000000000070700000000000000000077
00700000000000000000000007070000000000707000000000077070000000000707000000000077070000000000707000000000070700000000000000000700
00070000000000000000000007070000000000707000000000077070000000000707000000000077070000000000707000000000070700000000000000007000
80007000000000000000000007007000000007707000000000077070000000000707000000000077070000000000707000000000070700000000000000070000
88000700000000000000000000700777777770707000000000077070000000000707000000000077070000000000700700000000700700000000000000700007
88800700000000000000000000070000000000700700000000707070000000000707000000000077007000000007070077777777007000000000000000700077
88800070000000000000000000007777777777070077777777007007000000007700700000000700700777777770077000000000070000000000000007000077
88880070000000000000000000000000000000007000000000070700777777770070077777777007070000000000700777777777700000888888888887000007
88880070000000000000000000000000000000000777777777700070000000000707000000000070007777777777000000000888888888000000000007000000
78880070000000000000000000000000000000000000000000000007777777777000777777777700000000000000000888888000000000000000000007000000
77880070000000000000000000000000000000000000000000000000000000000000000000000000000000000008888000000000000000000000000007000000
77880070000000000000000000000000000000000000000000000000000000000000000000000000000000088880000000000000000000000000000007000000
77800070000000000000000000000000000000000000000000000000000000000000000000000000000888800000000000000000000000000000000007000000
77800700000000000000000000000000000000000000000000000000000000000000000000000000888000000000000000000000000000000000000000700000
78000700000000000000000000000000000000000000000000000000000000000000000000000888000000000000000000000000000000000000000000700000
80007000000000000000000000000000000000000000000000000000000000000000000000088000000000000000000000000000000000000000000000070000
00070000000000000000000000000000000000000000000000000000000000000000000088880880000000000000000000000000000000000000000000007000
00700000000000000000000000000000000000000000000000000000000000000000008800008008800000000000000000000000000000000000000000000700
77000000000000000000000000000000000000000000000000000000000000000000880000008000088000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000088000000000800000880000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000008800000000000800000008800000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000880000000000000080000000088000000000000000000000000000000000000ccc
00000000000000000000000000000000000000000000000000000000000088000000000000000080000000000880000000000000000000000000000000000c0c
00000000000000000000000000000000000000000000000000000000000800000000000000000080000000000008800000000000000000000000000000000c0c
00000000000000000000000000000000000000000000000000000000088000000000000000000008000000000000088000000000000000000000000000000c0c
00000000000000000000000000000000000000000000000000000000800000000000000000000008000000000000000880000000000000000000000000000ccc
00000000000000000000000000000000000000000000000000000008000000000000000000000000800000000000000008800000000000000000000000000000
00000000000000000000000000000000000000000000000000000880000000000000000000000000800000000000000000088000000000000000000000000000
00000000000000000000000000000000000000000000000000008000000000000000000000000000080000000000000000000880000000000000000000000000
00000000000000000000000000000000000000000000000000080000000000000000000000000000080000000000000000000008800000000000000000000000
00000000000000000000000000000000000000000000000000800000000000000000000000000000080000000000000000000000088000000000000000000000
00000000000000000000000000000000000000000000000008000000000000000000000000000000008000000000000000000000000880000000000000000000
00000000000000000000000000000000000000000000000080000000000000000000000000000000008000000000000000000000000008800000000000000000
00000000000000000000000000000000000000000000000800000000000000000000000000000000000800000000000000000000000000088000000000000000
00000000000000000000000000000000000000000000008000000000000000000000000000000000000800000000000000000000000000000880000000000000
00000000000000000000000000000000000000000000080000000000000000000000000000000000000080000000000000000000000000000008800000000000
00000000000000000000000000000000000000000000800000000000000000000000000000000000000080000000000000000000000000000000088000000000
00000000000000000000000000000000000000000000800000000000000000000000000000000000000080000000000000000000000000000000000880000008
00000000000000000000000000000000000000000008000000000000000000000000000000000000000008000000000000000000000000000000000008800880
00000000000000000000000000000000000000000080000000000000000000000000000000000000000008000000000000000000000000000000000000888000
00000000000000000000000000000000000000000800000000000000000000000000000000000000000000800000000000000000000000000000000888000880
00000000000000000000000000000000000000000800000000000000000000000000000000000000000000800000000000000000000000000000088000000008
00000000000000000000000000000000000000008000000000000000000000000000000000000000000000080000000000000000000000000088800000000000
00000000000000000000000000000000000000008000000000000000000000000000000000000000000000080000000000000000000000088800000000000000
00000000000000000000000000000000000000080000000000000000000000000000000000000000000000008000000000000000000008800000000000000000
00000000000000000000000000000000000000080000000000000000000000000000000000000000000000008000000000000000008880000000000000000000
00000000000000000000000000000000000000800000000000000000000000000000000000000000000000008000000000000000880000000000000000000000
00000000000000000000000000000000000000800000000000000000000000000000000000000000000000000800000000000888000000000000000000000000
00000000000000000000000000000000000000800000000000000000000000000000000000000000000000000800000000888000000000000000000000000000
00000000000000000000000000000000000008000000000000000000000000000000000000000000000000000080000088000000000000000000000000000000
00000000000000000000000000000000000008000000000000000000000000000000000000000000000000000080088800000000000000000000000000000000
00000000000000000000000000000000000008000000000000000000000000000000000000000000000000000088800000000000000000000000000000000000
00000000000000000000000000000000000008000000000000000000000000000000000000000000000000008808000000000000000000000000000000000000
00000000000000000000000000000000000080000000000000000000000000000000000000000000000008880008000000000000000000000000000000000000
00000000000000000000000000000000000080000000000000000000000000000000000000000000008880000000800000000000000000000000000000000000
00000000000000000000000000000000000080000000000000000000000000000000000000000000880000000000800000000000000000000000000000000000
00000000000000000000000000000000000080000000000000000000000000000000000000000888000000000000080000000000000000000000000000000000
00000000000000000000000000000000000080000000000000000000000000000000000000888000000000000000080000000000000000000000000000000000
00000000000000000000000000000000000080000000000000000000000000000000000088000000000000000000008000000000000000000000000000000000
00000000000000000000000000000000000080000000000000000000000000000000088800000000000000000000008000000000000000000000000000000000
00000000000000000000000000000000000080000000000000000000000000000088800000000000000000000000008000000000000000000000000000000000
00000000000000000000000000000000000080000000000000000000000000008800000000000000000000000000000800000000000000000000000000000000
00000000000000000000000000000000000080000000000000000000000008880000000000000000000000000000000800000000000000000000000000000000
00000000000000000000000000000000000080000000000000000000008880000000000000000000000000000000000080000000000000000000000000000000
00000000000000000000000000000000000080000000000000000000880000000000000000000000000000000000000080000000000000000000000000000000
00000000000000000000000000000000000008000000000000000888000000000000000000000000000000000000000008000000000000000000000000000000
00000000000000000000000000000000000008000000000000888000000000000000000000000000000000000000000008000000000000000000000000000000
00000000000000000000000000000000000008000000000088000000000000000000000000000000000000000000000008000000000000000000000000000000
00000000000000000000000000000000000008000000088800000000000000000000000000000000000000000000000000800000000000000000000000000000
00000000000000000000000000000000000000800088800000000000000000000000000000000000000000000000000000800000000000000000000000000000
00000000000000000000000000000000000000808800000000000000000000000000000000000000000000000000000000080000000000000000000000000000
00000000000000000000000000000000000000888888888888880000000000000000000000000000000000000000000000080000000000000000000000000000
00000000000000000000000000000000000000080000000000008888888888888888888888888880000000000000000000008000000000000000000000000000
00000000000000000000000000000000000000080000000000000000000000000000000000000008888888888888888888888888880000000000000000000000
00000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000008000008888888888888888888888
00000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000800000000000000000000000000
00000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000800000000000000000000000000
00000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000080000000000000000000000000
00000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000080000000000000000000000000
00000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000008000000000000000000000000
00000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000008000000000000000000000000
00000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000008000000000000000000000000
00000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000800000000000000000000000
00000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000800000000000000000000000
00000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000080000000000000000000000
00000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000080000000000000000000000
00000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000008000000000000000000000
00000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000008000000000000000000000
00000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000800000000000000000000
00000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000800000000000000000000
00000000000000000000000000000000000000000000000000000880000000000000000000000000000000000000000000000000000800000000000000000000
00000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000080000000000000000000
00000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000080000000000000000000
00000000000000000000000000000000000000000000000000000000088000000000000000000000000000000000000000000000000008000000000000000008
00000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000008000000000000000008
00000000000000000000000000000000000000000000000000000000000088000000000000000000000000000000000000000000000000800000000000000080
00000000000000000000000000000000000000000000000000000000000000880000000000000000000000000000000000000000000000800000000000000800
00000000000000000000000000000000000000000000000000000000000000008800000000000000000000000000000000000000000000800000000000000800
00000000000000000000000000000000000000000000000000000000000000000088000000000000000000000000000000000000000000080000000000008000
00000000000000000000000000000000000000000000000000000000000000000000880000000000000000000000000000000000000000080000000000080000
77000000000000000000000000000000000000000000000000000000000000000000008800000000000000000000000000000000000000008000000000080077
00700000000000000000000000000000000000000000000000000000000000000000000088800000000000000000000000000000000000008000000000800700
00070000000000000000000000000000000000000000000000000000000000000000000000088000000000000000000000000000000000000800000008007000
80007000000000000000000000000000000000000000000000000000000000000000000000000888000000000000000000000000000000000800000008070000
88000700000000000000000000000000000000000000000000000000000000000000000000000000888000000000000000000000000000000800000080700007
88800700000000000000000000000000000000000000000000000000000000000000000000000000000888800000000000000000000000000080000800700077
88800070000000000000000000000000000000000000000000000000000000000000000000000000000000088880000000000000000000000080000807000077
88880070000000000000000000000000000000000000000000000000000000000000000000000000000000000008888000000000000000000008008007000007
88880070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000888888000000000000008080007000000
78880070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000888888888000000880007000000
77880070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000888888888887000000
77880070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000
77800070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000
77800700000000000000000000000000000000000000000000000000000066606606660000000000000000000000000000000000000000000000000000700000
78000700000000000000000000000000000000000000000666066066600600068860006066606606660000000000000000000000000000000000000000700000
80007000000000000000000000000000000000000000006000688600066006606606600600068860006000000000000000000000000000000000000000070000
00070000000000000000000000000000000666066066660066066066060060000000066006606606600600000000000000000000000000000000000000007000
00700000000000000000000000000000006000688600600600000000660600000000060060000000060066660660666000000000000000000000000000000700
77000000000000000000000000000000060066066066606000060000060600000666060600000000006060006886000600000000000000000000000000000077
00000000000000000000000000000000600600000000606000066000060600006666660600000000006600660660660060000000000000000000000000000000
00000000000000000000000777077077606000060000606000066600060600066066060600006660006006000000006006000000000000000000000000000000
00000000000000000000007000788700606000066000606060666600060600066666660600060600006060006000600677777777777700000000000000000cc0
000000000000000000000700770770776060000666006060666666600606006666660606060666606060600066666607000000000000700000000000000000c0
000000000000000000007007000000006060606666006060666660600606066666600606006666660060600060666070777777777777070000000000000000c0
000000000000000000007070007000006060666666606060660600600606066600000606000666600060600066666670700000000007070000000000000000c0
00000000006660660666707000700000606066666060606006000060060060000000060600660666006060000000007070000000000707000000000000000ccc
00000000060006886000707007077700606066060060600600000000606006666666660060000000066060006666007070000000070707000000000000000000

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


pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
health_x=0
health_tx=0
preview_c=nil

function _init()
	palt(14,true)
	palt(0,false)
	init_players()
	c_game_logic=cocreate(game_logic)
end
function _draw()
	cls(0)	
	camera()
	local t=player.damaged_at and time()-player.damaged_at
	if(t and t<0.5)camera(rnd(5),rnd(3))
	t=opp.damaged_at and time()-opp.damaged_at
	if(t and t<0.5)camera(rnd(5),rnd(3))
	draw_player_hand()
	draw_hand(opp)
	draw_rows(player.rows)
	draw_rows(opp.rows, true)
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
	
	if(debug)then
		rectfill(0,0,128,8,0)
		print(debug,0,0,7)
	end
end

function _update()
	update_hand(player.hand,hand_i)
	update_rows()
	health_tx=(player_input!="hand" and -14 or 2)
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
		opp.v_hp=lerp(opp.v_hp, opp.hp,.3)
	end
	if(c_game_logic) then
		local _, err = coresume(c_game_logic)
  local status=costatus(c_game_logic)
  if status=="dead" then
  	local trace=trace(c_game_logic)
  	if(trace and not game_over)then
  		printh(err..": "..trace, "_ghosts.txt")
	  	cls(0)
	  	cursor()
	  	stop(err..": "..trace)
	  end
  end
	end
	if hit_frame then
		hit_frame+=1
	end
end

function draw_card(c,x,y,actor)
	if c=="endturn" then
		spr(66,x,y,2,2)
		return
	end
	local col  = (actor==opp or actor.mana>=c.cost) and 7 or 6
	pal(7,col)
	spr(64,x,y,2,2)
	if(actor==player)spr(c.s+(time()%1>0.5 and 1 or 0),x+4,y+4,1,1)
	
	pal(7,7)
end

function draw_hand(actor)
	local hand=actor.hand
	for i,hc in ipairs(hand) do
			draw_card(hc.c,hc.x,hc.y,actor)
	end
end
function draw_player_hand()
	draw_hand(player)
	local s_i=
		(player_input == "hand") 
		and hand_i 
		or nil

	local s_hc=player.hand[s_i]
	if s_hc then
		local c = s_hc.c
		draw_card(c,s_hc.x,s_hc.y,player)
		spr(16,s_hc.x+5,s_hc.y-6)
	end
		if s_hc and s_hc.c=="endturn" then
			print("end turn",s_hc.x+10-2*#"end turn",s_hc.y-12, 7)
		elseif preview_c and preview_c.name then
			local c =preview_c
			if s_hc then
				print(preview_c.name,s_hc.x+8 -2*#c.name,s_hc.y-12, 7)
			end
			local str = preview_c.type
			rectfill(64-2*#str,106,64+2*#str,110,0)
			print(str,64-2*#str,106,types[c.type])
			str = c.cost.." mana"
			rectfill(64-2*#str,106+7,64+2*#str,117,0)
			print(str,64-2*#str,106+7,7)
			str = c.atk.."/"..c.def..(
				c.desc and ", "..c.desc or ""
			)
			clip(22,0,84,128)
	
			local x = 64-2*#str
			if #str > 17 then
				preview_changed_at=preview_changed_at or 0
				local t=(time()-preview_changed_at)
				t %= (#str - 17)/3
				x=30-12*t
				
			end
			print(str,x,120,7)
			clip()
	end
end

function add_to_hand(hand,c)
	sfx(9)
	local i = #hand+1
	if hand==player.hand then
		i=#hand > 0 and #hand or 1
	end
	add(hand,{
		c=c,
		x=124,
		y=64
	}, i)
	
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
	preview_c=row[abs(preview_i)].c
end

function update_hand()
	local s_i=
		player_input == "hand" 
		and hand_i 
		or #player.hand/2+.5
	if(player_input == "hand")preview_c=player.hand[hand_i].c
	for i,hc in ipairs(player.hand) do
			local p = (i-s_i)/#player.hand
			local cx=64-18/2
			local w=18-#player.hand*.7
			local show_hand = player_input == "hand" or player_input == "view_board"
			w=max(8,w)
			local tx,ty = 
				cx+(i-s_i)*w,
				89+p*p*50
			if	not show_hand then
				ty+=30
			end
	
			hc.x=lerp(hc.x,tx,0.1)
			hc.y=lerp(hc.y,ty,0.1)
	end
	for i,hc in ipairs(opp.hand) do
				local p = (i-#opp.hand/2-.5)/#opp.hand
				local cx=64-18/2
				local w=18-#opp.hand*.7
				w=max(8,w)
				local tx,ty = 
					cx+(i-#opp.hand/2)*w,
					10-p*p*20
				if	player_input != "hand" then
					ty-=18
				end
				hc.x=lerp(hc.x,tx,0.1)
				hc.y=lerp(hc.y,ty,0.1)
		end
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
	if player_input=="hand" then
		if(btnp(➡️)) then 
			hand_i+=1
			preview_changed_at=time()
		end
		if(btnp(⬅️)) then
			hand_i-=1
			preview_changed_at=time()
		end
		if(btnp(⬆️)) then
			preview_i=1
			row_i=4
			move_view_board_cursor(0,-1)
			player_input="view_board"
		end
		if(hand_i < 1) hand_i = #player.hand
		if(hand_i > #player.hand) hand_i = 1
	end
end

function draw_rows(rows,flip)
	for i,row in ipairs(rows) do
		if not flip and player_input=="rows" then
			if row_i == i then
				spr(32,10*(1+#row),40+12*i,1,1,true)
			elseif row_i == -i then
				spr(32,0,40+12*i)
			end
		end
		
		for j,rc in ipairs(row) do
			local x,y=0+10*j,40+12*i

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
			
			if rc.hp < rc.c.def then
				line(x,y-2,x+7,y-2,8)	
				
				if rc.hp>0 then
					line(x,y-2,x+7*rc.hp/rc.c.def,y-2,7)	
				end
			end
					
			if player_input=="view_board" then
				if row_i == i then
					if preview_i*(flip and -1 or 1)==j then
						spr(16,x,y-7)
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
				palt(0,true)
				if t and t < .8 then
					pal(7,8)
				end
				local idle=time()%1>.5 and 1 or 0
				if rc.c.type=="object" and not rc.possessed then
					idle=0
				end
				spr(rc.c.s+idle,x,y,1,1,flip)
				palt(0,false)
				pal(7,7)
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

function print_centered(text, x, y, color)
 local tx= x- 2 * #tostr(text)
 local mx=128-4*#tostr(text)
 if tx<0 then
 	tx=0
 elseif tx>mx then
 	tx=mx
 end
 rectfill(-2+tx, y-1,
 x + 2 * #tostr(text), y+5, 0)
 print(text, tx, y, color or 7)
end

function draw_health(actor, y)
 local hp, mana, used_mana = actor.v_hp, actor.mana, actor.used_mana
 local health_x = health_x
	if actor==opp then
		health_x=106-health_x
	end
 -- draw health bar
 local p = hp / 20
 draw_bar(health_x, y, p, 8, 7, actor.damaged_at, 1/30, nil)
 print_centered(flr(hp), health_x + 10, y + 22, 8)

 -- draw mana bar
 p = mana / 7
 local x = 128 - health_x - 20
 draw_bar(x, y, p, 12, 7, actor.mana_flash_at, 0.6, 10)
 local str = tostr(mana) .. "/" .. tostr(mana + used_mana)
 local color = actor.mana_flash_at and time() - actor.mana_flash_at < 0.6 and 8 or 12
 print_centered(str, x + 10, y + 22, color)
end
-->8
--cards

types={
	beast=3,
	ghost=12,
	object=4,
	elemental=9,
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
local stone={name="stone",s=59,atk=1,def=5,cost=0,type="object"}

local bones={name="bones",s=23,atk=1,def=6,cost=2, type="ghost"}
goblin={
	name="goblin",s=53,atk=3,def=5,cost=6,type="beast",
	desc="summon goblin in every row", on_summon=function(actor,rc,row_i)
 	local rows={}
 	for i=1,3 do
 		if #actor.rows[i]<5 and i!=abs(row_i) then
 			gl_summon(actor, goblin, i, true)
 		end
 	end
 end
	}

cards={
    {name="devil",s=1,atk=1,def=5,cost=1, type="beast"},
    {name="spirit",s=3,atk=1,def=5,cost=2, type="ghost"},
    {name="blade",s=5,atk=3,def=4,cost=2, type="object"},
    {name="orb",s=7,atk=2,def=6,cost=1, type="object"},
    {name="golem",s=9,atk=3,def=12,cost=3, type="object"},
    {name="swarm",s=11,atk=2,def=2,cost=1, type="beast", desc="may draw swarm", on_summon=function(actor) 
        if(rnd()>.5)add_to_hand(actor.hand, cards[6])
    end},
    {name="jelpi",s=13,atk=1,def=8,cost=3, type="beast", desc="heal 4", on_summon=function(actor)
    actor.hp+=4
    end },
    {name="imp",s=17,atk=2,def=3,cost=1, type="beast"},
    {name="bat",s=19,atk=3,def=2,cost=2, type="beast"},
    {name="wil'o",s=21,atk=3,def=8,cost=4, type="ghost"},
    bones,
    {name="furniture",s=25,atk=1,def=6,cost=0, type="object"},
    {name="'geist",s=27,atk=3,def=10,cost=5, type="ghost"},
    {name="skelly",s=29,atk=2,def=8,cost=5, type="ghost", desc="summon bones", on_summon=function(actor)
        local rows={}
        for i=1,3 do
            if #actor.rows[i]<5 then
                add(rows,i)
            end
        end
        local row=rnd(rows)
        if(row)gl_summon(actor, bones, row, true)
    end},
   
    {name="slime",s=33,atk=1,def=8,cost=2, type="beast"},
    {name="blinky",s=35,atk=1,def=8,cost=3, type="ghost"},
    {name="candle",s=37,atk=2,def=2,cost=2, type="object", desc="+1 mana", on_summon=function(actor) if(actor.mana+actor.used_mana <6)actor.mana+=1 end},
    {name="snake",s=39,atk=3,def=3,cost=2, type="beast"},
    {name="'shroom",s=41,atk=1,def=6,cost=2, type="beast"},
    {name="lich",s=43,atk=3,def=14,cost=6, type="ghost"},
    {name="zap",s=45,atk=3,def=1,cost=3, type="elemental",
     desc="clear row",
     on_summon=function(actor,this,row_i)
       foreach_rc(function(rc, owner, i)
           if(i!=abs(row_i))return
           if(rc==this)return
           rc.hp = 0
           rc.damaged_at = time()
           sfx(11)
           for j = 1, 24 do yield() end
       end)  
       clear_dead()
   end,
    ai_will_play=function(actor)
       return 	foreach_rc(function(rc, owner, i)
           local mult=owner==actor and- 1 or 1
           return mult*rc.c.cost*rc.hp/rc.c.def
       end) >= 3
    end},
    {name="eye",s=49,atk=2,def=6,cost=4, type="beast", desc="animates all your objects", on_summon=function(actor)
       foreach_rc(function(rc, owner, i)
       if(owner!=actor or rc.c.type != "object" or rc.possessed ) return
        rc.possessed =true
        rc.possessed_at = time()
        sfx(14)
        for j = 1, 15 do yield() end
       end)
    end,
    ai_will_play=function(actor)
        return foreach_rc(function(rc, owner, i)
       if(owner!=actor or rc.c.type != "object" and  rc.possessed ) return
       return 1 + rc.c.cost
       end)>=3
    end},
   
    {name="relic",s=51,atk=1,def=5,cost=3, type="object", desc="kill all ghosts", on_summon=function(actor)
       foreach_rc(function(rc, owner, i)
        if(rc.c.type != "ghost")return
         rc.hp = 0
         rc.damaged_at = time()
         sfx(11)
         for j = 1, 24 do yield() end
         clear_dead()
        end)
    end,
    ai_will_play=function(actor)
       return foreach_rc(function(rc, owner, i)
           if(rc.c.type != "ghost")return
           local mult=actor==owner and -1 or 1
           return mult*rc.c.cost*rc.hp/rc.c.def
       end)>=3
    end},
       goblin,
       {name="flame",s=55,atk=3,def=3,cost=2, type="elemental", desc="2 damage to all foes", on_summon=function(actor)
           foreach_rc(function(rc, owner, i)
               if(owner == actor)return
               rc.hp -=2
               rc.damaged_at = time()
           end)
           sfx(11)
           for j = 1, 24 do yield() end
           clear_dead()
        end,
        ai_will_play=function(actor)
           return foreach_rc(function(rc, owner, i)
               if(owner == actor)return
               return (rc.hp<=2) and rc.c.cost or 1
           end) >= 4
    end},
    {name="gorgon",s=57,atk=3,def=6,cost=6, type="beast",
       desc="turn all foes to stone",
       on_summon=function(actor,rc,row_i)
           foreach_rc(function(rc, owner)
               if(owner==actor) return
               rc.c=stone
               rc.hp=min(stone.def,rc.hp)
               rc.possessed=false
               rc.damaged_at = time()
              end)
           sfx(11)
           for j = 1, 24 do yield() end
           clear_dead()
       end
       },
       {name="snail",s=61,atk=1,def=7,cost=2, type="beast",
       desc="kill foe at front of snail's row",
       on_summon=function(actor,rc,row_i)
           local foe=actor==player and opp or player
           local target_row=foe.rows[abs(row_i)]
           local target=target_row[#target_row]
           if(target==nil)return
           target.hp=0
           target.damaged_at=time()
           sfx(11)
           for j = 1, 24 do yield() end
           clear_dead()
       end,
       ai_will_play=function(actor,rc,row_i)
           local foe=actor==player and opp or player
           local score=0
           for target_row in all(foe.rows) do
               local target=target_row[#target_row]
               if target!=nil then
                   score+= target.c.cost*target.hp/target.c.def 
               end
           end
           return score/3>=2
       end},
	{name="cactus",s=68,atk=1,def=8,cost=3, type="elemental", desc="deal 3 damage to opponent", 
	on_summon=function(actor)
	 gl_damage_player(actor==player and opp or player, 3)
	end},
       {name="gargoyle",s=84,atk=3,def=14,cost=4, type="elemental", desc="costs 5 life", 
       on_summon=function(actor)
        gl_damage_player(actor, 5)
       end,
       ai_will_play=function(actor)
        foe=actor==player and opp or player
        return actor.hp > foe.hp and actor.hp > 10
       end
    },
   }
-->8

-->8

-->8
--game
hand_i = 1

function gl_new_game()
	for i=1,6 do
		yield()
		add_to_hand(player.hand, rnd(cards))
		add_to_hand(opp.hand, rnd(cards))
	end
end
function init_players()
player={
	hand={},
	rows={},
	pick_card=function()
			player_input="hand"
			yield()
			while true do
				if btnp(❎) and player_input=="hand" then
					local c=player.hand[hand_i].c
					if c!="endturn" and c.cost > player.mana then
						sfx(12)
						player.mana_flash_at=time()
					else
					player_input=nil
						return hand_i
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
			if btnp(🅾️) then
				return "back"
			end
			if btnp(❎) then
				if #player.rows[abs(row_i)]>=5 then
					sfx(12)
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
	pick_card=function(self)
			wait(.3)
			local value,opts=knapsack(opp, opp.hand, opp.mana)
			printh(value, "_ghosts.txt")
			printh(opts, "_ghosts.txt")

			return rnd(opts)
	end,
	select_row=ai_select_row
}
	player.hand={}
	opp.hand={}
	player.rows={{},{},{}}
	opp.rows={{},{},{}}
	player.hp=20
	opp.hp=player.hp
	player.v_hp=player.hp
	opp.v_hp=opp.hp
	opp.mana=0
	player.mana=0
	opp.used_mana=0
	player.used_mana=0
	player.turn_1=true
	add_to_hand(player.hand, "endturn")
end
function game_logic()
	gl_new_game()
	local actor=player
	while true do
		add_to_hand(actor.hand, rnd(cards))

		if(actor.mana+actor.used_mana<6)actor.mana+=1
		actor.mana+=actor.used_mana
		actor.used_mana=0
		
		while true do
			local card_i=actor:pick_card()
			if card_i == nil then
				break
			end			
			local c=actor.hand[card_i].c
			if c == "endturn" then
				break
			end	
			local row=actor:select_row(c)
			if row!="back" and c then
				deli(actor.hand, card_i)
				gl_summon(actor, c, row)
			end
		end
		
		for i=1,3 do
			gl_attack(player.rows[i], opp.rows[i], actor)
			if player.hp<=0 then
				game_over="game over"	
				return
			end
			if opp.hp<=0 then
				game_over="you win"
				return
			end
		end
		
		actor.turn_1=false
		actor = actor==player
			and opp 
			or player
	end
end


function gl_summon(actor,c,row_i, special)
	yield()
	if not special then
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
	sfx(13)
	wait(.8)
	if c.type=="ghost" then
		for other in all(row) do
			if other.c.type=="object" and not other.possessed then
				other.possessed=true
				other.possessed_at=time()
				sfx(14)
				wait(.5)
			end
		end
	end
	
	if c.type=="object" then
		for other in all(row) do
			if other.c.type=="ghost" and not other.possessed then
				rc.possessed=true
				rc.possessed_at=time()
				sfx(14)
				wait(.5)
				break
			end
		end
	end
	
	if not special and  c.on_summon then
		rc.ability_at=time()
		sfx(15)
		wait(.5)
		c.on_summon(actor, rc, row_i)
	end
end


function can_attack(rc, actor)
	if not rc or actor==player and actor.turn_1 then
		return false
	end
 return rc.possessed or rc.c.type!="object"
end

function get_defender(row, attacker)
 if attacker.c.type!="ghost" then
 	return row[#row]
 end
 local result=nil
 for _, rc in pairs(row) do
   if rc.c.type=="beast" 
   or (
   	rc.c.type=="object" and
   	not rc.possessed
   ) then
	--pass
   else
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
			sfx(10)
			if def_rc then
				def_rc.hp -= atk_rc.c.atk
				def_rc.damaged_at = time()
				sfx(11)
				wait(.8)
			else
				gl_damage_player(foe,atk_rc.c.atk)
			end
			wait(.25)
			any_damage=true
		end
	end		
	clear_dead()
end

function gl_damage_player(actor, dam)
	actor.hp -= dam
	actor.damaged_at = time()
	create_hit_spark(
		actor==player and 12 or 113,
		actor==player and 110 or 12,
		dam*1.6
	)
	sfx(16)
	wait(.8)
end	

function clear_dead()
	for i=1,3 do
 	for rc in all(opp.rows[i]) do
 		if rc.hp <= 0 then	
				del(opp.rows[i], rc)
			end
		end
 	for rc in all(player.rows[i]) do	
 	 if rc.hp <= 0 then	
				del(player.rows[i], rc)
			end
		end
	end
end
-->8
--util
function lerp(tar,pos,perc)
 return (1-perc)*tar + perc*pos;
end

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
	if no_wait then
		return
	end
	for j=0,30*s do
		yield()
	end
end
-->8
--ai

-- define utility functions to abstract repetitive logic
-- check for possession by a ghost
local function check_possession(row, c)
  local possessed = false
  if c.type == "object" then
    for other_rc in all(row) do
      if other_rc.c.type=="ghost" then
        possessed = true
        break
      end
    end
  end
  return possessed
end

-- add card to row and return if it can attack or not
local function get_pot_rc(row, c, owner)
  local pot_rc = {c=c, hp=c.def, possessed=check_possession(row, c)}
  return pot_rc, can_attack(pot_rc, owner)
end

-- main function body, now using utility functions
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
	if c.cost > mana or (c.ai_will_play and not c.ai_will_play(actor))  then
	 return knapsack(actor, cards, mana, n-1)
	else
	 local value1, subset1 = knapsack(actor, cards, mana - c.cost, n-1)
	 local value2, subset2 = knapsack(actor, cards, mana, n-1)
	
		local c=cards[n].c
		local card_value =  c.cost + 0.1
	 value1 = value1 + card_value
	
	 if value1 > value2 then
	     add(subset1, n)
	     return value1, subset1
	 else
	     return value2, subset2
	 end
	end
end


-->8
--hit spark
hit_x, hit_y, hit_mag, hit_res, hit_rs = 50, 50, 0, 18, nil


function create_hit_spark(x, y, mag)
	hit_x, hit_y, hit_frame, rs, hit_mag = x, y, 0, {}, mag
	for i=0, hit_res do add(rs, i%2==0 and (rnd(1.75)+1) or .8) end
	sfx(1)
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

__gfx__
00000000000707000000000000007770000000000000007700000000007777000077770000000000000000000770770000000000070007000070007000000000
00000000007777700007070000077777000077700000070700000077070000700700007000000000000000000770000007707700077777700077777700000000
00700700077707000077777000070770000777770000707000000707707000077000770700077700000777000007777007700000070777000070777000000000
00077000077777770777070000777777007707700007070000007070700077077000770700707000007070007007070000077770077777700077777700000000
00077000077777700777777707777770007777770770700000070700700077077070000700777700707777070777777770070700000000000000000000000000
00700700777777007777777007777700077777700077000007707000070000700700007007777770077777707777700077777777077770000077770000000000
00000000777777007777770077770000777777000707000000770000007777000077770070777707007777007707070077770000077777000777770000000000
00000000070070000700070077000000777000000000000007070000077777700777777007707770077077707007070070070700070000000000070000000000
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
eee7770770777eeeee777777777777ee000770000007700000000000077700000000000000000000000000000000000000000000000000000000000000000000
ee700078870007eee70000000000007e007777000077770007770000777770700000000000000000000000000000000000000000000000000000000000000000
e70077077077007e7077777777777707707070000070700777777007777707700000000000000000000000000000000000000000000000000000000000000000
70070000000070077070000000000707777777077077777777770777777777700000000000000000000000000000000000000000000000000000000000000000
70700000000007077070000000000707777707777777077777777777707077700000000000000000000000000000000000000000000000000000000000000000
70700000000007077070000000070707007777777777770070707777770777700000000000000000000000000000000000000000000000000000000000000000
70700000000007077070000000770707007777000077770077077007777770700000000000000000000000000000000000000000000000000000000000000000
70700000000007077070000007700707007777000077770007770000077700000000000000000000000000000000000000000000000000000000000000000000
70700000000007077070700077000707000000000777777000000000000000000000000000000000000000000000000000000000000000000000000000000000
70700000000007077070770770000707077777707700700000000000000000000000000000000000000000000000000000000000000000000000000000000000
70700000000007077070077700000707770070007777777700070700000000000000000000000000000000000000000000000000000000000000000000000000
70700000000007077070007000000707777777777070707000707070000707000000000000000000000000000000000000000000000000000000000000000000
70070000000070077070000000000707707070707000000000777770007070700000000000000000000000000000000000000000000000000000000000000000
e70077777777007e7077777777777707700000007000000007777770007777700000000000000000000000000000000000000000000000000000000000000000
ee700000000007eee70000000000007e770707077707070770070070077777700000000000000000000000000000000000000000000000000000000000000000
eee7777777777eeeee777777777777ee777777777777777777077077770770770000000000000000000000000000000000000000000000000000000000000000
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

__sfx__
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

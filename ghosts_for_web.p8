pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
health_x=0health_tx=0summary_y=128preview_c_wrapper=nil no_wait=false disable_tutorials=false function ssfx(e,n)sfx(e,n or 3)end function rpal()poke(24366,1)pal()pal({[0]=0,128,2,132,133,141,6,7,8,139,129,130,12,13,137,15},1)palt(14,true)palt(0,false)end function _init()parens8[[		(cartdata "demons_of_the_great_beyond")
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
		
	]]end function _draw_game()camera()local e=player.damaged_at and time()-player.damaged_at if(e and e<.5)camera(rnd(5),rnd(3))
e=opp.damaged_at and time()-opp.damaged_at if(e and e<.5)camera(rnd(5),rnd(3))
draw_rows(player.rows)draw_rows(opp.rows,true)draw_player_hand()opp.h_manager:draw()if(player.v_hp)draw_health(player,100)draw_health(opp,0)
draw_hit_spark()if(game_over)rectfill(0,60,128,68,8)print(game_over,64-#game_over*2,62,7)
local e,n=nil,time()-game_started_at n/=3if(n<2.5)e=64*((n-1)*(n-1)*(n-1)+.8)+10else e=188-2*summary_y
if(e and current_enemy)draw_enemy(current_enemy,e+10,e-32)rectfill(0,e,128,8+e,1)print("opponent "..tostr((current_enemy_index-1)%#enemies+1).."/"..tostr(#enemies)..": the "..current_enemy.name,2,e+2,7)
local e=time()-message_cleared_at e*=1.5if message_text or e<1do local n=time()-message_at n*=1.5local e=message_text and n or 1-e e=min(e,1)for t,n in ipairs(message_circles_back)do local e=e*12+1e+=2*sin(time()/3+t*.1)ovalfill(n.x-e,n.y-e,n.x+e,n.y+e,13)end for t,n in ipairs(message_circles_front)do local e=e*(e-1)*-4*12+1ovalfill(n.x-e,n.y-e,n.x+e,n.y+e,13)end for t,n in ipairs(message_circles_back)do local e=e*12e+=2*sin(time()/3+t*.1)ovalfill(n.x-e,n.y-e,n.x+e,n.y+e,0)end if(e>.5and message_text)print(message_text,2,70,7)color(5)print"❎ to continue"
for t,n in ipairs(message_circles_front)do local e=e*(e-1)*-4*12if(e>1)ovalfill(n.x-e,n.y-e,n.x+e,n.y+e,0)
end end end function _update_game()update_rows()health_tx=(player_input~="hand"or summary_y<100)and-14or 2summary_y=lerp(summary_y,player.h_manager.y_base+17,.07)if(player.damaged_at and time()-player.damaged_at<1or health_drawer_at and time()-health_drawer_at<2or opp.damaged_at and time()-opp.damaged_at<1or game_over)health_tx=2
health_x=lerp(health_x,health_tx,.2)if player.v_hp do player.v_hp=lerp(player.v_hp,player.hp,.3)if(abs(player.v_hp-player.hp)<.1)player.v_hp=player.hp
opp.v_hp=lerp(opp.v_hp,opp.hp,.3)if(abs(opp.v_hp-opp.hp)<.1)opp.v_hp=opp.hp
end update_hands(message_text~=nil)if message_text do local e=time()-message_at if(btnp(❎)and e>.8)message_ok()
return end player.h_manager.y_base=btn(⬇️)and player_input=="hand"and 60or 89if(time()>4and new_game_plus)message"in new game plus you no longer\nheal automatically between rounds"
if player_input=="hand"do local n={}for t,e in ipairs(player.h_manager.cards)do if(e.c~="endturn"and e.c.cost<=player.mana)add(n,e)
end if#n==0and time()>2do tutorial"you don't have enough mana to\nsummon any demons, end the turn"elseif time()>10and preview_c_wrapper and preview_c_wrapper.c.type=="ghost"do tutorial"hold ⬇️ to view detailed\ncard info"end if(foreach_rc(function()return 1end)>=4)tutorial"press ⬆️ to view the demons on\nthe board"
end if(player_input=="view_board"and current_enemy_index~=1)tutorial"hold ❎ to view the demons'\nattack and health"
if(current_enemy_index>=3)tutorial"you can view your deck from\nthe pause menu at any time"
local n=costatus(c_game_logic)if(c_game_logic and n~="dead")local t,e=coresume(c_game_logic)n=costatus(c_game_logic)if(n=="dead")local n=trace(c_game_logic)if n and e do log(e..": "..n)cls(0)cursor()stop(e..": "..n)elseif e do log("no trace: "..e)end
if(hit_frame)hit_frame+=1
end function draw_sprite(e,n,t)spr(e+(time()%1>.5and 1or 0),n+4,t+4,1,1)end function draw_deinterlaced(e,n,t,a,o)if(o)pal(split"5,5,8,8,8,7,7,7,8,8,8,14,14,14,8")palt(12,true)palt(13,true)palt(14,true)else pal(split"7,14,8,8,8,5,7,14,8,8,8,5,7,14,8")palt(2,true)palt(8,true)palt(14,true)
palt(0,false)pal(0,5)sspr(t,a,32,32,e,n)rpal()end function draw_enemy(e,n,t)draw_deinterlaced(n,t,e.facex,e.facey,e.facealt~=1)end function draw_card(a,o)local t,n,e=a.c,a.x,a.y if(a.ability_at)local n=time()-a.ability_at if(n<.5)e+=(n-.5)*n*100
if t=="endturn"or t=="skip"do spr(66,n,e,2,2)spr(96,n+4,e+4)return else if(t=="remove card")spr(66,n,e,2,2)spr(97,n+4,e+4)return else if(t=="heal 3")spr(66,n,e,2,2)spr(98,n+4,e+4)return
end local a=(o==nil or o==opp or o.mana>=t.cost)and 7or 6pal(7,a)pal(8,o==opp and 5or types[t.type])spr(64,n,e,2,2)if(o~=opp)draw_sprite(t.s,n,e)
pal(7,7)pal(8,8)end function draw_player_hand()player.h_manager:draw()local e=player_input=="hand"and player.h_manager.selected_index or nil local e=e and player.h_manager.cards[e]if(preview_c_wrapper and preview_c_wrapper.c.name)draw_summary(preview_c_wrapper,summary_y,summary_y<95)
end function draw_summary(n,e,a)local t,o=n.c or n,n.hp and n or nil local n=t.type mark_card_seen(t)rectfill(64-2*#n,e,64+2*#n,e+4,0)print(n,64-2*#n,e,types[t.type])e+=7rectfill(64-2*#n,e,64+2*#n,e+4,0)if(o and o.hp~=t.def)n=t.cost.."✽, "..t.atk.."/"local n=print(n,64-2*#n,e,7)print(o.hp,n,e,8)else n=t.cost.."✽, "..t.atk.."/"..t.def..""print(n,64-2*#n,e,7)
e+=7if(a)for n in all(type_desc[t.type])do rectfill(64-2*#n,e,64+2*#n,e+4,0)print(n,64-2*#n,e,types[t.type])e+=7end
if t.desc do n=t.desc local o,t=64-2*#n,a and 30or 12clip(64-t*3,0,t*2*3,128)if(#n>t)preview_changed_at=preview_changed_at or 0local e=(time()-preview_changed_at)*6e%=#n-t+8o=(a and 16or 40)-e*4
rectfill(0,e,128,e+4,0)print(n,o,e,7)clip()end end shown_messages={}message_stack={}message_at=0message_cleared_at=0function tutorial(n,e)e=e or n if(disable_tutorials)return
message(n,e)end function message(n,e)e=e or n if(not shown_messages[n])shown_messages[n]=true if(message_text==nil)message_at=time()message_text=e else add(message_stack,e)
end function message_ok()if(#message_stack>0)message_text=deli(message_stack,1)else message_text=nil message_cleared_at=time()
end function move_view_board_cursor(e,a)preview_changed_at=time()if abs(a)>0do local e=sgn(preview_i)==1and player or opp local n,n,t=e==opp and player or opp,preview_i,row_i while true do t+=a if(abs(t)>3)player_input="hand"break
if(t<0)break
local e=e.rows[t]if(e and#e>0and abs(n)>#e)n=sgn(n)*#e
if(e and e[abs(n)])row_i=t preview_i=n break
end else local n=sgn(preview_i)==1and player or opp local t,n=n==opp and player or opp,n.rows[row_i]local a=t.rows[row_i]if abs(preview_i+e*sgn(row_i))>0do preview_i+=e if n and abs(preview_i)>#n do if#a>0do preview_i=-#a*sgn(preview_i)else preview_i-=e*sgn(preview_i)if(row_i==3)row_i+=1
for e=0,2do local e=(e+row_i)%3+1local n=#t.rows[e]if(n>0)preview_i=-n*sgn(preview_i)row_i=e break
end end end end end local e=sgn(preview_i)==1and player or opp local e=e.rows[row_i]local e=e and e[abs(preview_i)]preview_c_wrapper=e end function update_hands(e)player.h_manager.enabled=player_input=="hand"if(player_input=="hand")preview_i=player.h_manager.selected_index local e=player.h_manager.cards[preview_i]preview_c_wrapper=e
player.h_manager:update(e)opp.h_manager:update(e)if player_input=="view_board"do if(btnp(➡️))move_view_board_cursor(1,0)
if(btnp(⬅️))move_view_board_cursor(-1,0)
if(btnp(⬇️))move_view_board_cursor(0,1)
if(btnp(⬆️))move_view_board_cursor(0,-1)
end end function has_board_ability(e)return e.on_void or e.double_abilites_for or e.double_damage_to_opponent or e.can_attack or e.can_defend or e.on_kill end function draw_rows(e,o)for a,e in ipairs(e)do if(not o and player_input=="rows")if row_i==a do spr(32,10*(1+#e),35+14*a,1,1,true)elseif row_i==-a do spr(32,0,35+14*a)end
for d,e in ipairs(e)do local n,t=0+10*d,35+14*a if e.attacking_at do local a=time()-e.attacking_at local o=clamp(a/.4,0,1)if(a>1.1)o=clamp((a-1.1)/.4,0,1)n=lerp(60,n,ease(o))else n=lerp(n,60,ease(o))
local a=clamp((a-.5)/.5,0,1)if(a<.5)n-=a*(a-.5)*e.attacking_x t+=a*(a-.5)*e.attacking_y
end if(e.damaged_at)local e=time()-e.damaged_at if(e<.6)n+=rnd()*3-1
if(e.possessed_at)local e=time()-e.possessed_at if(e<.5)t+=e*(e-.5)*70
if(o)n=128-n
if(e.hp<e.c.def and not(btn(❎)and player_input=="view_board"))line(n,t-2,n+7,t-2,8)if(e.hp>0)line(n,t-2,n+7*e.hp/e.c.def,t-2,7)
if player_input=="view_board"and not btn(❎)do if(row_i==a)if(preview_i*(o and-1or 1)==d)spr(16,n,t-8)print_centered(e.c.name,n+4,t-12)
end local a=e.summoned_at and time()-e.summoned_at if(a and a<.71428)local e=100-140*a local o=e*.6draw_pentagram(n-e+4,t-o+8,n+e+4,t+o+8,a*a,8)else e.summoned_at=nil
if a==nil or a>.6do if btn(❎)and player_input=="view_board"do local a=types[e.c.type]if(has_board_ability(e.c))a=time()%1>.5and 7or a
local n=print(e.c.atk<=9and e.c.atk or"+",n,t,a)n=print("/",n-1,t+2,a)n=print(e.hp<=9and e.hp or"+",n-1,t+4,e.hp<e.c.def and 8or a)else palt(0,true)if(a and a<.8)pal(7,8)
local a=time()%1>.5and 1or 0if(e.c.type=="object"and not e.possessed or e.c.can_attack and not e.c.can_attack(e)or e.frozen)a=0
pal(7,0)spr(e.c.s+a,n,t+1,1,1,o)spr(e.c.s+a,n,t-1,1,1,o)spr(e.c.s+a,n+1,t,1,1,o)spr(e.c.s+a,n-1,t,1,1,o)pal(7,e.frozen and 12or 7)spr(e.c.s+a,n,t,1,1,o)palt(0,false)pal(7,7)end end if(a and a>2)e.summoned_at=nil
if(e.ability_at)local e=time()-e.ability_at if(e<.5)local e=e*20oval(n-e+4,t-e+4,n+e+4,t+e+4,7)
end end end function update_rows()if player_input=="rows"do local n,e=sgn(row_i),abs(row_i)if(btnp(⬆️))e-=1
if(btnp(⬇️))e+=1
if(btnp(➡️)or btnp(⬅️))n*=-1
if(e<1)e=3
if(e>3)e=1
row_i=n*e end end function draw_bar(e,n,d,o,a,t,r,c)local t=t and time()-t local r=t and t<r and o or a ovalfill(e,n,e+20,n+20,0)oval(e,n,e+20,n+20,a)clip(0,n+(1-d)*20,128,128)ovalfill(e+3,n+3,e+17,n+17,o)clip(0,0,128,128)ovalfill(e+5,n+5,e+8,n+8,a)ovalfill(e+10,n+10,e+15,n+15,a)if(t and t<.6)e+=sin(t*10)
end function print_centered(n,a,t,r,e)local o=e or 4*#tostr(n)local e,d=a-o/2,128-4*#tostr(n)if e<0do e=0elseif e>d do e=d end rectfill(-2+e,t-1,a+o/2,t+5,0)print(n,e,t,r or 7)end function draw_health(e,t)local d,a,r,n=e.v_hp,e.mana,e.used_mana,health_x if(e==opp)n=106-n
local o=d/e.max_hp draw_bar(n,t,o,8,7,e.damaged_at,.03333,nil)print_centered(flr(d),n+10,t+22,8)o=a/7local n=128-n-20draw_bar(n,t,o,12,7,e.mana_flash_at,.6,10)local a,e=tostr(a).."✽/"..tostr(a+r).."✽",e.mana_flash_at and time()-e.mana_flash_at<.6and 8or 12print_centered(a,n+10,t+22,e,30)end function draw_pentagram(e,n,t,a,o,d)oval(e,n,t,a,d)local e,n,t,a=(e+t)/2,(n+a)/2,(t-e)/2,(a-n)/2for r=0,4do local o,r=o+.4*r,o+.4*(r-1)local o,c,e,n=sin(o)*t+e,cos(o)*a+n,sin(r)*t+e,cos(r)*a+n line(o,c,e,n,d)end end function imut_add(n,t)local e={}for n in all(n)do add(e,n)end add(e,t)return e end function clamp(e,n,t)if(e>t)return t
if(e<n)return n
return e end function lerp(n,t,e)return n*(1-e)+t*e end function ease(e,n)n=n or 3if(e<.5)return e^n*2
e=1-e return 1-e^n*n*2end function wait(e)while message_text~=nil do yield()end if no_wait do if(rnd()<.25)yield()
return end for e=0,30*e do yield()end end function parens8(e)_pstr,_ppos="id "..e..")",0return compile({parse()},function(e)return e,1end){{_𝘦𝘯𝘷}}end function id(...)return...end function consume(e,n)local t=_ppos while(function()for e in all(e)do if(_pstr[_ppos]==e)return true
end end)()==n do _ppos+=1end return sub(_pstr,t,_ppos-1)end function parse(e)_ppos+=e or 1consume(" \n	",true)local e=_pstr[_ppos]if(e=="(")return{parse()},parse()
if(e==")")return
if(e=='"'or e=="'")_ppos+=1return{"quote",consume(e)},parse()
local e=consume" \n	()'\""return tonum(e)or e,parse(0)end builtin={}function compile_n(e,n,...)if(n)return compile(n,e),compile_n(e,...)
end function compile(e,n)if type(e)=="string"do local t,a=split(e,"."),e=="..."if(t[2]and not a)return fieldview(n,deli(t,1),t)
local e,n=n(e)if(a)return n and function(t)return unpack(t[1][n],e)end or function(n)return unpack(n,e)end
return n and function(t)return t[1][n][e]end or function(n)return n[e]end end if(type(e)=="number")return function()return e end
local t=deli(e,1)if(builtin[t])return builtin[t](n,unpack(e))
local function a(e,...)local n=...and a(...)return n and function(t)return e(t),n(t)end or e end local e,n=compile(t,n),a(compile_n(n,unpack(e)))return n and function(a)local e=e(a)if(e)return e(n(a))
assert(false,t.." was nil")end or function(n)local e=e(n)if(e)return e()
assert(false,t.." was nil")end end function builtin:quote(e)return function()return e end end function builtin:fn(o,d)local e,n,t,a=parens8[[(quote ()) (quote ()) (quote ())]]for n,t in inext,o do e[t]=n end local e=compile(d,function(o)local e=e[o]if(e)return e+1,false
local o,e=self(o)if(e)n[e]=true else a=true
return o,e or t end)return a and function(a)local t={[t]=a}for e in next,n do t[e]=a[1][e]end return function(...)return e{t,...}end end or function(n)return function(...)return e{n[1],...}end end end parens8[[(fn (closure) (rawset builtin "when" (fn (lookup e1 e2 e3)
	(closure (compile_n lookup e1 e2 e3))
)))
]](function(t,a,n)return function(e)if(t(e))return a(e)
if(n)return n(e)
end end)parens8[[(fn (closures) (rawset builtin "set" (fn (lookup exp1 exp2)
	((fn (compiled fields) ((fn (head tail) (when tail
		(select 3 (closures compiled tail (fieldview lookup head fields)))
		((fn (idx where) (select (when where 1 2)
			(closures compiled idx where)
		)) (lookup head))
	)) (deli fields 1) (deli fields))) (compile exp2 lookup) (split exp1 "."))
)))
]](function(e,n,t)return function(a)a[1][t][n]=e(a)end,function(t)t[n]=e(t)end,function(a)t(a)[n]=e(a)end end)parens8[[(fn (closure) (set fieldview (fn (lookup tab fields view) (select -1
	(set view (fn (step i field) (when field (view
		(closure step field)
		(inext fields i)
	) step)))
	(view (compile tab lookup) (inext fields))
))))
]](function(e,n)return function(t)return e(t)[n]end end)function builtin.table(...)return parens8[[	(fn (exp) ((fn (closures lookup construct) (select -1
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
	]]{function(e,n,o)return function(t,a)t[o]=n(a)return e(t,a)end,function(t,a)add(t,n(a))return e(t,a)end,function(n)return(e({},n))end end,...}end function repack(e)return function(...)return e{...}end end parens8[[(fn (unroll) (rawset builtin "seq" (repack
    (fn (args) ((fn (lookup e1 e2 e3) 
        ((fn (s1 s2) (select (mid 3 (rawlen args)) s1 (unroll s1 s2 (when e3
            ((rawget builtin "seq") lookup (unpack args 3)))))
        ) (compile_n lookup e1 e2))
    ) (deli args 1) (unpack args)))
) ((fn (func) (rawset builtin "fn" (repack (fn (args)
    (func (deli args 1) (deli args 1) (pack "seq" (unpack args)))
)))) (rawget builtin "fn")) ))
]](function(n,t,a)return function(e)n(e)return t(e)end,function(e)n(e)t(e)return a(e)end end)parens8[[(fn (closures) ((fn (ops loopfn) (select -1
	(set loopfn (fn (i op) (when i (loopfn (select 2
		(rawset builtin op (fn (lookup e1 e2 e3)
			(select i (closures (compile_n lookup e1 e2 e3)))
		))
		(inext ops i)
	)))))
	(loopfn (inext ops))
)) (split "+,-,*,/,\,%,^,<,>,<=,>=,==,~=,..,or,and,not,#,[]")))
]](function(e,n,a)return function(t)return e(t)+n(t)end,n and function(t)return e(t)-n(t)end or function(n)return-e(n)end,function(t)return e(t)*n(t)end,function(t)return e(t)/n(t)end,function(t)return e(t)\n(t)end,function(t)return e(t)%n(t)end,function(t)return e(t)^n(t)end,function(t)return e(t)<n(t)end,function(t)return e(t)>n(t)end,function(t)return e(t)<=n(t)end,function(t)return e(t)>=n(t)end,function(t)return e(t)==n(t)end,function(t)return e(t)~=n(t)end,function(t)return e(t)..n(t)end,function(t)return e(t)or n(t)end,function(t)return e(t)and n(t)end,function(n)return not e(n)end,function(n)return#e(n)end,a and function(t)e(t)[n(t)]=a(t)end or function(t)return e(t)[n(t)]end end)parens8[[(foreach (split "+,-,*,/,\,%,^,..") (fn (op)
	(rawset builtin (.. op "=") (fn (lookup e1 e2)
		(compile (pack "set" e1 (pack op e1 e2)) lookup)
	))
))
]]parens8[[(rawset builtin "let" (fn (lookup exp2 exp3) (
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
]]parens8[[(fn (closure) (rawset builtin "while" (fn (lookup cond body)
	(closure (compile_n lookup cond body))
)))
]](function(n,t)return function(e)while(n(e))t(e)
end end)parens8[[(fn (closures) (rawset builtin "for" (fn (lookup args body)
	(when (rawget args 3)
		(select 1 (closures
			(compile (pack "fn" (pack (rawget args 1)) body) lookup)
			(compile_n lookup (unpack args 2))))
		(select 2 (closures
			(compile (pack "fn" (rawget args 1) body) lookup)
			(compile (rawget args 2) lookup)))
	)
)))
]](function(n,t,o,a)return function(e)local n=n(e)for e=t(e),o(e),a and a(e)or 1do n(e)end end,function(e)local o,n,t=n(e),t(e)local function a(e,...)if(e==nil)return
o(e,...)return a(n(t,e))end return a(n(t))end end)deck_scene={init=function(e)e.cards=player.og_deck e.i=1e.h_manager=create_hand_manager{cards=e.cards,spacing=32,height=300,y_base=40,on_move=function()preview_changed_at=time()end}e.removed_card=nil e.removed_card_at=nil end,update=function(e)if not e.removed_card_at do e.h_manager:update()if(btnp(🅾️))pop_scene()
if(e.is_removing and btnp(❎))e.is_removing=false del(player.og_deck,e.h_manager:get_card())ssfx(43)e.h_manager.enabled=false e.removed_card=e.h_manager:get_card()e.removed_card_at=time()
else e.h_manager:get_hc().dy=e.h_manager:get_hc().dy or 0e.h_manager:get_hc().dy-=1e.h_manager:get_hc().y+=e.h_manager:get_hc().dy if(time()-e.removed_card_at>1)start_new_game(current_enemy_index+1)c_game_logic=cocreate(game_logic)pop_scene()pop_scene()
end end,draw=function(e)e.h_manager:draw()draw_summary(e.h_manager:get_card(),64,true)print_centered("view deck",64,10)print("press 🅾️ to go back",2,120,6)if(e.is_removing)print("press ❎ to remove",2,110,6)
print(e.h_manager.selected_index.."/"..#e.cards,2,2,7)end}menuitem(1,"view deck",function()push_scene(deck_scene)end)menuitem(2,"title screen",function()load"ghosts_wrapper.p8"end)menuitem(3,"toggle music",function()music_disabled=not music_disabled poke(24137,music_disabled and 1or 0)if(music_disabled)music(-1,500)else music(17,2000)
end)game_scene={draw=_draw_game,update=_update_game}scenes={}current_scene=nil function push_scene(e)if(current_scene==e)return
add(scenes,e)current_scene=e if(e.init)e:init()
end function pop_scene()del(scenes,current_scene)current_scene=scenes[#scenes]if(current_scene.resume)current_scene:resume()
end function _update()if(current_scene)current_scene:update()
end function _draw()cls()memcpy(24576,32768,8192)if(current_scene)current_scene:draw()
end push_scene(game_scene)function gl_new_game()for e=1,4do yield()gl_draw_card(player)gl_draw_card(opp)end player.h_manager:add_to_hand("endturn")end function map_to_cards(n)local e={}for n in all(n)do add(e,cards[n])end return e end function new_player_deck()local e={}for n in all(cards)do for t=1,n.start_count or 0do add(e,n)end end local t,n=rnd{-1,0,0,1,2}+12,{}for t=1,t do add(n,rnd(e))end return n end function start_new_game(e)current_enemy_index=e current_enemy=enemies[(e-1)%#enemies+1]srand(seed)save_progress()game_started_at=time()player={hand={},rows={},og_deck=player and player.og_deck or new_player_deck(),hp=new_game_plus and player.hp or 16,max_hp=16,pick_card=function()player_input="hand"yield()while true do if(btnp(❎)and player_input=="hand")local e=player.h_manager:get_card()if(e~="endturn"and e.cost>player.mana)ssfx(38)player.mana_flash_at=time()else player_input=nil return e
yield()end end,select_row=function()player_input="rows"row_i=-1yield()while true do if(player.rows[abs(row_i)]and#player.rows[abs(row_i)]>=1)tutorial"demons can be summoned at the\n front or back of a row"
if(btnp(🅾️))return"back"
if(btnp(❎))if(#player.rows[abs(row_i)]>=5)ssfx(38)else player_input=nil return row_i
yield()end end}opp={hand={},rows={},og_deck=map_to_cards(current_enemy.deck),pick_card=function(e)wait(.3)local n,e=knapsack(opp,opp.h_manager.cards,opp.mana)return rnd(e)end,select_row=ai_select_row}player.h_manager=create_hand_manager{cards={},on_move=function()preview_changed_at=time()end,on_up=function()player_input="view_board"preview_i=1row_i=4move_view_board_cursor(0,-1)if(preview_c_wrapper==nil)preview_i=-1row_i=4move_view_board_cursor(0,-1)if(preview_c_wrapper==nil)player_input="hand"
end,actor=player}opp.h_manager=create_hand_manager{cards={},enabled=false,inverted=true,actor=opp,y_base=12}player.rows={{},{},{}}opp.rows={{},{},{}}opp.hp=ceil(current_enemy.max_hp*(new_game_plus and 1.5or 1))opp.max_hp=opp.hp player.v_hp=player.hp opp.v_hp=opp.hp opp.mana=0player.mana=0opp.used_mana=0player.used_mana=0player.turn_1=true player.deck=shallow_copy(player.og_deck)opp.deck=shallow_copy(opp.og_deck)game_over=nil end function shallow_copy(n)local e={}for n,t in pairs(n)do e[n]=t end return e end function gl_draw_card(e)ssfx(35)if(#e.deck==0)e.h_manager:add_to_hand(void)return
local n=rnd(e.deck)del(e.deck,n)e.h_manager:add_to_hand(n)end function gl_steal_card(n)local t,e=n==player and opp or player,{}for n in all(t.h_manager.cards)do if(type(n.c)~="string")add(e,n)
end if(#e>0)local e=rnd(e)local a,o,e=e.x,e.y,e.c t.h_manager:remove(e)n.h_manager:add_to_hand(e,a,o)ssfx(43)
end function gl_tutor(e,t)local n={}for e in all(e.deck)do if(t(e))add(n,e)
end if(#n==0)ssfx(38)else local n=rnd(n)del(e.deck,n)e.h_manager:add_to_hand(n)ssfx(43)
end function game_logic()gl_new_game()local e=player while true do foreach_rc(function(e)if(e.frozen)e.frozen-=1if(e.frozen==0)e.frozen=nil
end)gl_draw_card(e)if(e.mana+e.used_mana<6)e.mana+=1else tutorial"once you have 6 mana you\nwill no longer more each turn"tutorial"(demon abilities can bypass\nthis limit)"
e.mana+=e.used_mana e.used_mana=0while true do local n=e:pick_card()if(n==nil)break
if(n=="endturn")break
local t=e:select_row(n)if(t==nil)break
if(t~="back"and n)e.h_manager:remove(n)gl_summon(e,n,t,false,false)check_game_end()if(game_over)return
end for n=1,3do gl_attack(player.rows[n],opp.rows[n],e)check_game_end()if(game_over)return
end e.turn_1=false e=e==player and opp or player end end function check_game_end()if(player.hp<=0)game_over="game over"clear_save()wait(4)load"ghosts_wrapper.p8"return true
if opp.hp<=0do seed=rnd()local e=(current_enemy_index-1)%9+1local t,n=peek(24137+e),ceil(current_enemy_index/9)if(t<n)poke(24137+e,n)
if(current_enemy==enemies[9])current_enemy_index+=1save_progress()game_over="you won the game!"wait(4)load"ghosts_wrapper.p8"return true else save_progress()game_over="victory!"wait(1)push_scene(reward_scene)return true
end end function get_doubler(e,n)for t=1,3do local e=e.rows[t]for t,e in pairs(e)do if(e.c.double_abilites_for and e.c.double_abilites_for(n))return e
end end return false end function gl_summon(n,e,a,t,d)local o=n.rows[abs(a)]if(#o>=5)return
yield()if(not t)n.mana-=e.cost n.used_mana+=e.cost
local t,o={c=e,hp=e.def,summoned_at=time()},n.rows[abs(a)]add(o,t,a<0and 1or#o+1)ssfx(39)wait(.8)if e.type=="ghost"do for e in all(o)do if(e.c.type=="object"and not e.possessed)e.possessed=true e.possessed_at=time()ssfx(40)wait(.5)
end end if e.type=="object"do for e in all(o)do if(e.c.type=="ghost")t.possessed=true t.possessed_at=time()ssfx(40)wait(.5)break
end end local o=get_doubler(n,e)if(e.on_summon and not d)as_ability(t,n,function()e.on_summon(n,t,a)end)
if e==void do foreach_rc(function(e,t)if(t~=n)return
if(e.c.on_void)as_ability(e,t,function()e.c.on_void(e,t)end)
end)end if(e.type=="object")if(t.possessed)tutorial"this object has been possessed,\nand can now attack"else tutorial"this object cannot attack,\nuntil possessed by a ghost"
check_game_end()end function can_attack(e,n)if(not e or n==player and n.turn_1)return false
if(e.frozen)return false
if(not e.possessed and e.c.type=="object")return false
if(e.c.atk<=0)return false
if(e.c.can_attack and not e.c.can_attack(e))return false
return true end function can_defend(e,n)if n.c.type=="ghost"do if(e.c.type=="beast")return false
if(e.c.type=="object"and not e.possessed)return false
end if(e.c.can_defend)return e.c.can_defend(e,n)
return true end function get_defender(n,t)local e=nil for a,n in pairs(n)do if(can_defend(n,t))e=n
end return e end function gl_attack(n,a)local t,e,d=n[#n],a[#a],false for e in all{t,e}do local t=e==t and player or opp local o,a=t==player and opp or player,t==player and a or n if e and can_attack(e,t)do local n,a=get_defender(a,e),a[#a]if(a~=nil and n~=a)if a.c.can_defend do tutorial"some demons' abilities stop\nthem from blocking"elseif e.c.type=="ghost"and a.c.type=="beast"do tutorial"beasts cannot block ghosts!"end wait(0)
e.attacking_at=time()if(n)e.attacking_x=100e.attacking_y=0else e.attacking_x=100e.attacking_y=t==player and 200or-200
if(not n)health_drawer_at=time()
wait(.6)ssfx(36)if n do n.hp-=e.c.atk n.damaged_at=time()ssfx(37,1)wait(.8)if(n.hp<=0and e.c.on_kill)n.killed_by=e
else gl_damage_player(o,e.c.atk)if(e.c.double_damage_to_opponent)as_ability(e,t,function()e.attacking_at=time()wait(.6)gl_damage_player(o,e.c.atk)end)
end wait(.25)d=true end end clear_dead()end function as_ability(e,t,n)tutorial("ability","some demons, like "..e.c.name..", have\nspecial abilities")e.ability_at=time()ssfx(41)wait(.5)n()local t=get_doubler(t,e.c)if(t)t.ability_at=time()ssfx(41)wait(.4)e.ability_at=time()ssfx(41)wait(.5)n()
end function gl_damage_player(e,n)e.hp-=n e.damaged_at=time()create_hit_spark(e==player and 12or 113,e==player and 110or 12,n*1.6)ssfx(36)wait(.8)end function clear_dead()for n=1,3do for e in all(opp.rows[n])do if(e.hp<=0)del(opp.rows[n],e)if(e.killed_by and e.killed_by.c.on_kill)as_ability(e.killed_by,player,function()e.killed_by.c.on_kill(player,e.killed_by,e,n)end)
end for e in all(player.rows[n])do if(e.hp<=0)del(player.rows[n],e)if(e.killed_by and e.killed_by.c.on_kill)as_ability(e.killed_by,opp,function()e.killed_by.c.on_kill(opp,e.killed_by,e,n)end)
end end end types={beast=9,ghost=12,object=15,elemental=14}type_desc={beast={"can't block ghosts"},ghost={"can't be blocked by beasts","or by unpossessed objects.","possess allied objects on row"},object={"can't block ghosts or","attack if unpossessed."},elemental={}}function foreach_rc(a)local e=0for n=1,3do for t in all{player,opp}do local o=t.rows[n]for o in all(o)do e+=a(o,t,n)or 0end end end return e end function foreach_hc(n,t)local e=0for n in all(n.h_manager.cards)do e+=t(n)or 0end return e end cards={}void={}enemies={}parens8[[(set enemies (table))

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
]]function log(e)printh(e,"_ghosts.txt")end function check_possession(e,n)if n.type=="object"do for e in all(e)do if(e.c.type=="ghost")return true
end end return false end function get_pot_rc(n,e,t)local e={c=e,hp=e.def,possessed=check_possession(n,e)}return e,can_attack(e,t)end function ai_select_row(a,o)local e,d,r,t,c=nil,{},{},{},{}for n=1,3do local a=a.rows[n]if#a<5do add(c,n)local c=player.rows[n]local e=c[#c]if(not can_attack(e,player))e=nil
local o,l=get_pot_rc(a,o,opp)local s,i,o=e and get_defender(a,e),e and get_defender(imut_add(a,o),e),l and get_defender(c,o)if(e and not s and i)add(r,n)
if(not o and l)add(t,n)
if(#a==0)add(d,n)
end end if opp.hp>player.hp and#t>0do e=rnd(t)elseif#r>0do e=rnd(r)elseif#d>0do e=rnd(d)elseif#t>0do e=rnd(t)else return rnd(c)end local n=opp.rows[abs(e)]local t,a,n=n[#n],get_pot_rc(n,o,opp)if(not n)return-e
local n=t and can_attack(t,opp)and t.c.atk or 0if(o.atk>=n)return e
if(o.def>=8)return-e
return rnd{1,-1}*e end function knapsack(a,n,t,e)e=e or#n if(e<=0or t<=0)return 0,{}
local o=n[e].c if(o=="endturn")return knapsack(a,n,t,e-1)
if(o.cost>t or o.ai_will_play and not o.ai_will_play(a))return knapsack(a,n,t,e-1)else local o,d=knapsack(a,n,t-o.cost,e-1)local t,a=knapsack(a,n,t,e-1)local e=n[e].c local n=e.cost*e.cost+.1o=o+n if(o>t)add(d,e)return o,d else return t,a
end hit_x,hit_y,hit_mag,hit_res,hit_rs=50,50,0,18,nil function create_hit_spark(e,n,t)hit_x,hit_y,hit_frame,rs,hit_mag=e,n,0,{},t for e=0,hit_res do add(rs,e%2==0and rnd(1.75)+1or.8)end end function draw_hit_spark()if(not hit_frame or hit_frame>6)return
local e,a,e,n,t=hit_frame,hit_frame for a=0,hit_res do e,n,t=a/hit_res,hit_mag*hit_frame*rs[a+1],hit_mag*hit_frame*rs[a%hit_res+2]fillp(hit_frame>5and ░ or hit_frame>3and ▒ or 0)line(hit_x+sin(e)*n,hit_y+cos(e)*n,hit_x+sin(e+1/hit_res)*t,hit_y+cos(e+1/hit_res)*t,7)if(hit_frame==1and rnd()<.4)line(hit_x,hit_y,hit_x+sin(e)*(rnd(12)+3)*hit_mag,hit_y+cos(e)*(rnd(12)+3)*hit_mag,7)
end fillp(0)end function create_hand_manager(e)local n={cards={},selected_index=e.selected_index or 1,on_hc_selected=e.on_hc_selected,on_up=e.on_up,on_down=e.on_down,on_x=e.on_x,on_o=e.on_o,on_move=e.on_move,inverted=e.inverted,get_preview=e.get_preview,y_base=e.y_base or 89,x_base=e.x_base or 64,spacing=e.spacing or 18,height=e.height or 50,actor=e.actor,enabled=true}if(e.enabled==false)n.enabled=false
function n.get_hc(e)return e.cards[e.selected_index]end function n.get_card(e)return e.cards[e.selected_index].c end function n.add_to_hand(e,t,a,o)local n=nil for t=#e.cards,1,-1do if(type(e.cards[t].c)=="string")n=t break
end add(e.cards,{c=t,x=a or 124,y=o or 64},n)end function n.remove(e,t)for a,n in ipairs(e.cards)do if(n.c==t)del(e.cards,n)break
end end function n.update(e,n)if e.enabled and not n do if(btnp(⬅️))e.selected_index-=1if(e.on_move)e.on_move()
if(btnp(➡️))e.selected_index+=1if(e.on_move)e.on_move()
if(e.on_up and btnp(⬆️))e.on_up(e)
if(e.on_down and btnp(⬇️))e.on_down(e)
if(e.on_x and btnp(❎))e.on_x(e.cards[e.selected_index].c)
if(e.on_o and btnp(🅾️))e.on_o()
if(e.selected_index<1)e.selected_index=#e.cards
if(e.selected_index>#e.cards)e.selected_index=1
end local a=e.enabled and e.selected_index or#e.cards/2+.5for o,n in ipairs(e.cards)do local d,r,t=(o-a)/#e.cards,e.x_base-e.spacing/2,e.spacing-#e.cards*.7t=max(8,t)local t,e=r+(o-a)*t,e.y_base+d*d*e.height*(e.inverted and-1or 1)n.x=lerp(n.x,t,.1)n.y=lerp(n.y,e,.1)end end function n:draw()for n,e in ipairs(self.cards)do draw_card(e,self.actor)end local e=self.cards[self.selected_index]if(e)draw_card(e,self.actor)
local e=self.enabled and self.cards[self.selected_index]if(e)spr(16,e.x+5,e.y-7)local n=type(e.c)=="string"and e.c or e.c.name print_centered(n,e.x+8,e.y-12,7)
end for t,e in ipairs(e.cards)do n:add_to_hand(e)end return n end reward_scene={init=function(e)e.rewards={}reward_scene_at=time()local n={}for e=1,#cards do add(n,cards[e])end for t=1,3do local t=rnd(n)del(n,t)add(e.rewards,t)end add(e.rewards,"skip")if(new_game_plus)add(e.rewards,"heal 3")
add(e.rewards,"remove card")e.h_manager=create_hand_manager{cards=e.rewards,y_base=32,on_x=function(e)if(time()-reward_scene_at<.6)return
if e=="remove card"do push_scene(deck_scene)deck_scene.is_removing=true return elseif e=="heal 3"do player.hp+=3elseif type(e)=="table"do add(player.og_deck,e)ssfx(40)end start_new_game(current_enemy_index+1)c_game_logic=cocreate(game_logic)pop_scene()end}end,update=function(e)e.h_manager:update()end,draw=function(e)print("pick a reward",16,10,7)local n=e.h_manager:get_card()if(type(n)=="table")draw_summary(n,64,true)
e.h_manager:draw()end}function save_deck()if(not player.og_deck)return
for e=0,32do local n=player.og_deck[e+1]local n=n and indexof(cards,n)or 0poke(24064+e,n)end end function indexof(e,n)for e,t in ipairs(e)do if(t==n)return e
end end function load_deck()player.og_deck={}for e=0,32do local e=24064+e local e=peek(e)if(e>0)add(player.og_deck,cards[e])
end end function save_progress()save_deck()if(current_enemy_index>=4)disable_tutorials=true
poke(24097,current_enemy_index)poke4(24098,seed)local e=peek4(24098)poke(24102,player.hp)poke(24128,disable_tutorials and 1or 0)end function load_progress()current_enemy_index=peek(24097)seed=peek4(24098)disable_tutorials=peek(24128)==1if(current_enemy_index<=1)return false
load_deck()player.hp=peek(24102)return true end function clear_save()memset(24064,0,64)end function mark_card_seen(n)local e=0for t,a in ipairs(cards)do if(a==n)e=t break
end if(e==0)return
local n,e=(e-1)\8,(e-1)%8local n=24129+n local t=peek(n)local a,e=t&1<<e,t|1<<e poke(n,e)end
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
070000070000000000777000000000000007770000077700000777000000000007077700070777000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
077000770700000707070000007770000770700000707070007070000007770070707000707070000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
007777700770007707777000070700000777777007777770007777000070700000777700007777070000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
077077070077777000000000077770000777777007777770007707000077770007000007000000000000000000000000eeeeeeeeeeee00000000eeeeeeeeeeee
007700700770770707777707000000000777777007777700077777700077070000770700707707000000000000000000eeeeeeeeeee0700777770eeeeeeeeeee
077777700777007007700707077777070077770007777700077707700777777007777770077777700000000000000000eeeeeeeeee070777777770eeeeeeeeee
777777707777777000000000077007077077700070777000077777700777077000000000000000000000000000000000eeeeeeeee07007777700770eeeeeeeee
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

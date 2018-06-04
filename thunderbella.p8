pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- thunder bella the cloud chaser by evil paper
-- funky chiptune by gruber

-- todo
-- add "electric" lighting effect on thunderbolts
-- add better game over tune

-- sfx
sfx_rain=0
sfx_start_game=1
sfx_game_over=9
sfx_p_stun=3
sfx_p_recover=4
sfx_p_knocked_down=5
sfx_thunder=6
sfx_bounce=7
sfx_fireworks=8
sfx_rocket=2
sfx_rocket_storm=25
sfx_create_powerup=10
sfx_pickup_powerup=11
sfx_extra_life=12
sfx_thunderstrike=13
sfx_bomb=19

-- initialize game ------------
function _init()
 t = 0
 shake = 0
 time_since_last_thunderbolt=0
 max_number_of_thunderbolts=2
 time_to_next_thunderbolt=120
 btn_counter=0
 boss = {
   x=51,
   y=7,
   t=0,
   lives=50,
   dx=0.4,
   ddx=0.05,
   left_eye_sprite=36,
   right_eye_sprite=36,
   destination=51,
   left_pupil_sprite=39,
   left_pupil_x=53,
   left_pupil_y=6,
   right_pupil_sprite=39,
   right_pupil_x=72,
   right_pupil_y=6,
   hitbox={x=0,y=5,w=32,h=8},
   state="idle",
   flashing_timer=0
  }
  cloud = {
   y=0,
   sprite=80
 }
 explosions = {}
 glows = {}
 fireworks = {}
 freeze_timer=0
 p = {
   x=56,
   y=112,
   t=0,
   lives=3,
   sprite=0,
   direction=0,
   state="idle",
   hitbox={x=2,y=5,w=12,h=10},
   flashing_timer=0,
   attack="regular",
   shoot_count=0,
   att_pow=1
  }
 popups = {}
 powerups = {}
 puffts = {}
 rain_fg = {}
 rain_bg = {}
 rockets = {}
 score = 0
 splashes = {}
 smoke={}
 thunder=0
 thunderbolts = {}
 thunderstrikes = {}
 time_between_ts = 240
 time_since_last_thunderbolt_was_created=0
 time_since_last_thunderbolt_was_deleted=0
 wind = {
   dx=rnd(1.5)-0.5
  }
 music(00)
 create_rain_in_background()
 create_rain_in_foreground()
end
-- end of initalization -------

-- scenes ---------------------
scene = {}
scene.active = 0
scene.update = {}
scene.draw = {}

scene.cycle = function(num)
  t=0
  scene.active = num
end

scene.reset = function()
 scene.active = 0
end

scene.updates = function()
 if scene.update[scene.active] != nil then
  scene.update[scene.active]()
 end
end

scene.drawing = function()
 if scene.draw[scene.active] != nil then
  scene.draw[scene.active]()
 end
end
-------------------------------

-- title scene specifics ------
scene.update[0] = function()
  if x_btn then
   sfx(sfx_start_game)
   scene.cycle(1)
  end
end

scene.draw[0] = function()
  --print("how to play",44,80,6)
  print("left/right arrow to move",16,84,6)
  print("x button to shoot rockets",14,92,6)
  circfill(48,50+(flr(t/16)%2),8,1)
  circfill(68,56+(flr(t/16)%2),20,1)
  circfill(46,62+(flr(t/16)%2),10,1)
  circfill(84,54+(flr(t/16)%2),10,1)
  circfill(80,66+(flr(t/16)%2),10,1)
  circfill(58,66+(flr(t/16)%2),12,1)
  spr(192,44,50+(flr(t/16)%2),8,4)
  if (abs(t % 30) <= 20) print("press x to start", 36,103,7)
end
-------------------------------

-- game on scene specifics ----
scene.update[1] = function()
 if freeze_timer>0 then
  freeze_timer-=1
 end
 if freeze_timer==2 then
  music(00)
 end
 shoot_rocket()
 check_collision_rocket_vs_thunderbolt()
 check_collision_rocket_vs_boss()
 check_collision_thunderbolt_vs_player()
 check_collision_thunderstrike_vs_player()
end

scene.draw[1] = function()
  draw_score()
  draw_lives()
end
-------------------------------

-- game over scene specifics --
scene.update[2] = function()
  update_rockets()
  if t>60 and x_btn then
    _init()
    scene.cycle(1)
  end
end

scene.draw[2] = function()
  draw_backdrop()
  if (abs(t % 30) <= 20) print("ouch!",57,56,7)
  if (abs(t % 30) <= 20) print("game over",48,64,7)
  if t>60 then
    if (abs(t % 30) <= 20) print("press x to try again",25,99,7)
  end
  draw_score()
  draw_lives()
end
-------------------------------

-- game won scene specifics ---
scene.update[3] = function()
  if t>60 and x_btn then
    _init()
    scene.cycle(1)
  end
end

scene.draw[3] = function()
  draw_backdrop()
  if (abs(t % 30) <= 20) print("boss",57,56,7)
  if (abs(t % 30) <= 20) print("defeated",50,64,7)
  if (abs(t % 30) <= 20) print("press x for a new round",19,99,7)
  draw_score()
  draw_lives()
end

-------------------------------

--- create functions ----------

function create_firework(_x,_y)
 sfx(sfx_fireworks)
 for i=0,50 do
  create_firework_particles(_x,_y)
 end
end

function create_firework_particles(_x,_y)
 local angle = rnd()
 local speed = 0.5+rnd(1)
 local new = {
   x=_x,
   y=_y,
   dx=sin(angle)*speed,
   dy=cos(angle)*speed,
   age=flr(rnd(25))
 }
 add(fireworks,new)
end

function create_pufft(x,y,dx)
 local pufft = {
   x=x+rnd(7),
   y=y,
   dx=dx,
   dy=-rnd(0.4),
   r=3+rnd(1),
   age=0,
   maxage=25,
   col=7
 }
 add(puffts,pufft)
end

function create_explosion(x,y)
 for i=0,2 do
   local explosion = {
     x=x-4+rnd(8),
     y=y-4+rnd(8),
     r=10,
     age=0-i,
     maxage=12,
     col={7,7,7,0,0,7,9,9,9,0,4,4}
   }
   add(explosions,explosion)
 end
end

function create_glow(x,y)
 for i=1,10 do
  local glow = {
   x=x+(rnd(16)),
   y=y+(rnd(8)),
   dx=-0.2+rnd(0.4),
   dy=-0.3-rnd(0.7),
   r=1+rnd(1),
   age=0,
   maxage=70,
   col=7
  }
  add(glows,glow)
 end
end

function create_smoke(x,y,dx,dy,quantity)
 for i=1,quantity do
   local smoke_particle = {
     x=x+rnd(6),
     y=y+16+rnd(4),
     dx=dx,
     dy=dy,
     r=1+rnd(2),
     age=0,
     maxage=10,
     col=6
   }
   add(smoke, smoke_particle)
 end
end

function create_rain_in_background()
 for i=1,256 do
  add(rain_bg, {
   x=rnd(384)-128,
   y=rnd(128),
   dx=0,
   dy=rnd(2)+1
  })
 end
end

function create_rain_in_foreground()
 for j=1,256 do
  add(rain_fg, {
   x=rnd(384)-128,
   y=rnd(128),
   dx=0,
   dy=rnd(1.5)+1.5,
   color=12,
   sprite=55,
   state="falling"
   })
 end
end

function create_splash(x,y)
 for i=1, rnd(10)+2 do
  local splash = {
   x=x,
   y=y,
   dx=(rnd(3)-2),
   dy=-rnd(2)-1,
   r=(rnd(2)+1),
   colour=12
  }
  if splash.r <= 2 then splash.colour = 6 end
  add(splashes,splash)
 end
end

-------------------------------

--- reset functions ----------

function reset_raindrop(raindrop)
 raindrop.x=rnd(384)-128
 raindrop.y=rnd(128)-128
 raindrop.sprite=55
 raindrop.state="falling"
end

function reset_thunderbolts()
 for l in all(thunderbolts) do
   del(thunderbolts,l)
 end
end

--- update functions  ---------

function update_input()
 left_btn=btn(0)
 right_btn=btn(1)
 x_btn=btn(5)
end

function update_clouds()
  if (t%50<16) then
   cloud.y=0
   cloud.sprite=80
   boss.y=11
   boss.left_pupil_y=boss.y
   boss.right_pupil_y=boss.y
  elseif (t%50<32) then
   cloud.y=-1
   cloud.sprite=82
   boss.y=9
   boss.left_pupil_y=boss.y
   boss.right_pupil_y=boss.y
  else
   cloud.y=-2
   cloud.sprite=84
   boss.y=7
   boss.left_pupil_y=boss.y
   boss.right_pupil_y=boss.y
  end
end

function update_fireworks()
 for p in all(fireworks) do
  if p.age > 40
   or p.y > 128
   or p.y < 0
   or p.x > 128
   or p.x < 0
   then
   del(fireworks,p)
  else
   p.x+=p.dx
   p.y+=p.dy
   p.age+=1
   p.dy+=0.075
  end
 end
end

function update_puffts()
 for p in all(puffts) do
  if p.age >= p.maxage
   or p.y > 128
   or p.y < 0
   or p.x > 128
   or p.x < 0
   then
   del(puffts,p)
  else
   if p.age>=0 then
    p.x+=p.dx
    p.y+=p.dy
    p.r-=0.1
   end
   p.age+=1
  end
 end
end

function update_glows()
 for g in all(glows) do
   if g.age >= g.maxage
    or g.y > 128
    or g.y < 0
    or g.x > 128
    or g.x < 0
    then
     del(glows,g)
   else
    if g.age>=0 then
     g.x+=g.dx
     g.y+=g.dy
     g.r-=0.02
    end
    g.age+=1
   end
  end
end

function update_explosions()
 for e in all(explosions) do
   if e.age >= e.maxage then
     del(explosions,e)
   else
     e.r-=0.5
     e.age+=1
   end
 end
end

function update_smoke()
 for s in all(smoke) do
  if s.age >= s.maxage
    or s.y > 128
    or s.y < -16
    or s.x > 128
    or s.x < 0
  then
     del(smoke,s)
  else
    if s.age>=0 then
      s.x+=s.dx + wind.dx
      s.y+=s.dy
      s.r-=0.05
    end
    s.age+=1
  end
 end
end

function update_splash()
 for splash in all(splashes) do
  splash.x+=splash.dx
  splash.y+=splash.dy
  splash.dy+=1
  if (splash.y>130) del (splashes,splash)
 end
end

function update_wind()
 if t%20==0 then
  wind.dx=wind.dx+rnd(1)-0.5
  if wind.dx > 1 then
   wind.dx = 1
  end
  if wind.dx < -1 then
   wind.dx = -1
  end
 end
end

function update_rain_fg()
 for raindrop_fg in all(rain_fg) do
  if raindrop_fg.state=="falling" then
   raindrop_fg.dx *= 0.45 -- add friction
   raindrop_fg.x += wind.dx
   raindrop_fg.y += raindrop_fg.dy
   if raindrop_fg.y > 128 then
    raindrop_fg.state="splashing"
   end
  end
  if raindrop_fg.state=="splashing" then
   raindrop_fg.y=120
   raindrop_fg.sprite+=0.5
   if raindrop_fg.sprite==59 then
    reset_raindrop(raindrop_fg)
   end
  end
 end
end

function update_rain_bg()
 for raindrop_bg in all(rain_bg) do
  raindrop_bg.x += wind.dx
  raindrop_bg.y += raindrop_bg.dy
  if raindrop_bg.y >= 128 then
   raindrop_bg.y = 0
   raindrop_bg.x=rnd(384)-128
  end
 end
end

function _update60()
 t=t+1
 scene.updates()
 update_input()
 update_player()
 update_puffts()
 if freeze_timer==0 then
  update_wind()
  update_clouds()
  update_boss()
  update_rain_fg()
  update_rain_bg()
  update_thunderbolts()
  update_thunderstrikes()
 end
 update_explosions()
 update_glows()
 update_smoke()
 update_splash()
 update_rockets()
 update_fireworks()
 update_popups()
 update_powerups()
 check_collision_player_vs_powerup()
end

--- draw functions  -----------

function draw_backdrop()
  circfill(48,54+(flr(t/8)%2),8,1)
  circfill(68,60+(flr(t/8)%2),20,1)
  circfill(46,66+(flr(t/8)%2),10,1)
  circfill(84,58+(flr(t/8)%2),10,1)
  circfill(80,70+(flr(t/8)%2),10,1)
  circfill(58,72+(flr(t/8)%2),12,1)
end

function draw_splash()
 for splash in all(splashes) do
  circfill(splash.x,splash.y,splash.r,splash.colour)
 end
end

function draw_puffts()
 for p in all(puffts) do
  if p.age>=0 then
   draw_pufft(p)
  end
 end
end

function draw_pufft(p)
 circfill(p.x,p.y,p.r,p.col)
end

function draw_glows()
 for g in all(glows) do
  if g.age>=0 then
   draw_glow(g)
  end
 end
end

function draw_glow(g)
 circfill(g.x,g.y,g.r,g.col)
end

function draw_explosions()
 for e in all(explosions) do
  if e.age>=0 then
   draw_explosion(e)
  end
 end
end

function draw_explosion(e)
 local color = e.col[e.age]
 circfill(e.x,e.y,e.r,color)
end

function draw_smoke()
 for s in all(smoke) do
  if s.age>=0 then
    draw_smoke_particle(s)
  end
 end
end

function draw_smoke_particle(s)
 circfill(s.x,s.y,s.r,s.col)
end

function draw_fireworks()
 local col
 for p in all(fireworks) do
  if p.age > 60 then col=8
  elseif p.age > 40 then col=9
  elseif p.age > 20 then col=10
  else col=7 end
  line(p.x,p.y,p.x+p.dx,p.y+p.dy,col)
 end
end

function change_colors_to_white()
  for i=1,15 do
    pal(i,7)
  end
end

function reset_color_to_normal()
  return pal()
end

function draw_background_rain()
  for raindrop_bg in all (rain_bg) do
   pset(raindrop_bg.x,raindrop_bg.y,1)
  end
end

function draw_foreground_rain()
  for raindrop_fg in all(rain_fg) do
    if raindrop_fg.state=="falling" then
      color(raindrop_fg.color)
      if wind.dx > 1 then
        line (raindrop_fg.x,raindrop_fg.y,raindrop_fg.x+0.3,raindrop_fg.y+1)
      elseif wind.dx < -1 then
        line (raindrop_fg.x,raindrop_fg.y,raindrop_fg.x-0.3,raindrop_fg.y+1)
      else
        line (raindrop_fg.x,raindrop_fg.y,raindrop_fg.x,raindrop_fg.y+1)
      end
    else
     spr(raindrop_fg.sprite,raindrop_fg.x,raindrop_fg.y)
    end
  end
end

function draw_cloud()
  map(0,0,0,cloud.y,16,16)
  spr(cloud.sprite,-6,20+cloud.y,2,1)
  spr(cloud.sprite,7,28+cloud.y,2,1)
  spr(cloud.sprite,10,18+cloud.y,2,1)
  spr(cloud.sprite,19,23+cloud.y,2,1)
  spr(cloud.sprite,36,23+cloud.y,2,1)
  spr(cloud.sprite,82,22+cloud.y,2,1)
  spr(cloud.sprite,47,29+cloud.y,2,1)
  spr(cloud.sprite,71,28+cloud.y,2,1)
  spr(cloud.sprite,96,28+cloud.y,2,1)
  spr(cloud.sprite,108,21+cloud.y,2,1)
  spr(cloud.sprite,118,18+cloud.y,2,1)
end

function draw_lives()
  for i=1,p.lives do
   spr(52,128-i*8,2)
  end
end

function shake_screen()
  local shakex=8-rnd(16)
  local shakey=8-rnd(16)

  shakex*=shake
  shakey*=shake

  camera(shakex,shakey)

  shake=shake*0.95
  if (shake<0.05) shake = 0
end

function draw_score()
 if boss.lives>=0 then
  print(boss.lives,1,1,13)
 end
end

function _draw()
 if (thunder>0) then
  rectfill(0,0,128,128,7)
 else
  rectfill(0,0,128,128,13)
 end
 draw_background_rain()
 draw_foreground_rain()
 draw_thunderstrikes()
 draw_cloud()
 draw_boss()
 draw_thunderbolts()
 draw_splash()
 draw_player()
 draw_glows()
 draw_explosions()
 draw_smoke()
 draw_rockets()
 draw_fireworks()
 shake_screen()
 draw_popups()
 draw_powerups()
 scene.drawing()
end
-->8
--player

function player_hit()
 sfx(sfx_p_stun)
 shake+=1
 p.lives-=1
 change_state(p,"electric")
 if p.lives == 0 then
   boss.state="laughing"
   scene.cycle(2)
 end
end

function update_player()
  if p.state=="idle" then
	 local start_frame=0
   local animation_speed=12
   p.sprite=start_frame+flr((t/animation_speed)%4)*2
   if (left_btn or right_btn) then
     change_state(p,"walking")
   end
   if (x_btn) change_state(p,"shooting")
  end

  if p.state=="walking" then
   if (left_btn) p.direction=-1
   if (right_btn) p.direction=1
   local start_frame=12
   local animation_speed=4
   if (x_btn) and p.sprite!=73 then
     p.sprite=73 else
     p.sprite=start_frame+flr((t/animation_speed)%2)*2
   end
   p.x+=p.direction*1.5
   if (not (left_btn or right_btn)) change_state(p,"idle")
   --if p.x>128 and p.direction==1 then p.x=-20 end
   --if p.x<-16 and p.direction==-1 then p.x=132 end
   if p.x<=0 then p.x=0 end
   if p.x>=112 then p.x=112 end
  end

  if p.state=="shooting" then
   p.sprite=73
   change_state(p,"idle")
  end

  if p.state=="electric" then
   local start_frame=8
   local animation_speed=12
   p.sprite=start_frame+flr((t/animation_speed)%2)*2
   p.y=112
   p.t+=1
   if p.t > 70 then
    if p.lives>0 then
     create_glow(p.x,p.y)
     change_state(p,"idle")
     p.flashing_timer=60
     boss.state="idle"
     sfx(sfx_p_recover)
    else
     sfx(sfx_p_knocked_down)
     change_state(p,"falling")
    end
    p.t=0
   end
  end

  if p.state=="falling" then
   local start_frame=96
   local animation_speed=26
   p.sprite=start_frame+flr((t/animation_speed)%6)*2
   if p.sprite==104 then
     change_state(p,"knocked_out")
   end
  end

  if p.state=="knocked_out" then
   reset_thunderbolts()
   game_over=true
	 local start_frame=106
   local animation_speed=8
   p.sprite=start_frame+flr((t/animation_speed)%3)*2
  end
end

function draw_player()
  if (isflashing(p)) then
    change_colors_to_white()
  end
  spr(p.sprite,p.x,p.y,2,2,p.direction==-1)
  reset_color_to_normal()
--  if (#glows>0) then

--  end
end
-->8
--enemy

function get_boss_sprite(state)
  if (t%50<16) then
    if state=="idle" or "moving" then return 36
    elseif state=="laughing" then return 36 end
  elseif (t%50<32) then
    if state=="idle" or "moving" then return 34
    elseif state=="laughing" then return 36 end
  else
    if state=="idle" or "moving" then return 32
    elseif state=="laughing" then return 36 end
  end
end

function get_boss_destination()
 if p.x<=60 then return p.x+16+rnd((128-(p.x+16+32))) end
 if p.x>60 then return rnd((p.x-42)) end
end

function get_moving(boss)
 boss.destination=get_boss_destination()
 boss.t=0
 boss.dx=0.4
 boss.ddx=0.07
 if boss.x > boss.destination then
  boss.dx=-boss.dx
  boss.ddx=-boss.ddx
 end
 boss.state="moving"
end

function update_boss()
 boss.t+=1
 boss.x+=boss.dx
 boss.dx+=boss.ddx
 if boss.x <=0 then 
  boss.x=1 
  boss.state="idle"
 end
 if boss.x >=96 then 
  boss.x=95 
  boss.state="idle"
 end
 if boss.state=="idle" then
    boss.left_pupil_sprite=39
    boss.right_pupil_sprite=39
    boss.dx=0
    boss.ddx=0
    boss.left_eye_sprite=get_boss_sprite("idle")
    boss.right_eye_sprite=get_boss_sprite("idle")
    if scene.active==1 and boss.t>45 then
     get_moving(boss)
    end
 end
 if boss.state=="moving" then
    boss.left_pupil_sprite=39
    boss.right_pupil_sprite=39
    boss.dx=boss.dx+boss.ddx
    boss.left_eye_sprite=get_boss_sprite("moving")
    boss.right_eye_sprite=get_boss_sprite("moving")
    if boss.dx > 0 and boss.t>2 and boss.t<8 then
      create_pufft(boss.x-8,boss.y,-0.3)
    elseif boss.dx < 0 and boss.t>2 and boss.t<8 then
      create_pufft(boss.x+34,boss.y,0.3)
    end
    if boss.dx < 0 and boss.x <= boss.destination then
     boss.t=0
     boss.state="idle"
    elseif boss.dx > 0 and boss.x >= boss.destination then
     boss.t=0
     boss.state="idle"
    end
 end
 if boss.state=="laughing" then
    boss.dx=0
    boss.ddx=0
    boss.left_pupil_sprite=38
    boss.right_pupil_sprite=38
    boss.left_eye_sprite=get_boss_sprite("laughing")
    boss.right_eye_sprite=get_boss_sprite("laughing")
 end

 update_boss_pupils()
end

function update_boss_pupils()
  if p.x < boss.x-10 then
   boss.left_pupil_x=boss.x+1
   boss.right_pupil_x=boss.x+20
  elseif p.x >= boss.x-10 and p.x <= boss.x+30 then
   boss.left_pupil_x=boss.x+2
   boss.right_pupil_x=boss.x+21
  else
   boss.left_pupil_x=boss.x+3
   boss.right_pupil_x=boss.x+22
  end
end

function draw_boss_eyes()
  spr(boss.left_eye_sprite,boss.x,boss.y,2,1)
  spr(boss.right_eye_sprite,boss.x+16,boss.y,2,1,true)
  spr(boss.left_pupil_sprite,boss.left_pupil_x,boss.left_pupil_y)
  spr(boss.right_pupil_sprite,boss.right_pupil_x,boss.right_pupil_y)
end

function draw_boss()
  if (isflashing(boss)) then
    for i=1,15 do
      pal(i,7)
    end
  end
  draw_boss_eyes()
  pal()
  draw_puffts()
end

function draw_boss_laugh()
  if boss.state=="laughing" then
    if (t%50<16) then
      spr(44,boss.x+8,boss.y+8,1,1)
      spr(44,boss.x+16,boss.y+8,1,1,true)
    elseif (t%50<32) then
      spr(45,boss.x+8,boss.y+8,1,1)
      spr(45,boss.x+16,boss.y+8,1,1,true)
    else
      spr(46,boss.x+8,boss.y+8,1,1)
      spr(46,boss.x+16,boss.y+8,1,1,true)
    end
  end
end


-->8
--helpers (collision etc.)

function animate(thing)
  thing.t=(thing.t+1)%thing.step
  if (thing.t==0) thing.frame=thing.frame%#thing.sprite+1
end

function change_state(thing,new_state)
 thing.state=new_state
end

function collide(a,b)
 if a.x+a.hitbox.x+a.hitbox.w < b.x+b.hitbox.x then return false end
 if a.y+a.hitbox.y+a.hitbox.h < b.y+b.hitbox.y then return false end
 if a.x+a.hitbox.x > b.x+b.hitbox.x+b.hitbox.w then return false end
 if a.y+a.hitbox.y > b.y+b.hitbox.y+b.hitbox.h then return false end
 return true
end

function check_collision_rocket_vs_thunderbolt()
 if count(rockets) > 0 then
  for thunderbolt in all(thunderbolts) do
   for rocket in all(rockets) do
    if collide(thunderbolt,rocket) then
     create_firework(rocket.x,rocket.y)
     create_smoke(thunderbolt.x,thunderbolt.y-16,0.1,-0.3,100)
     shake+=0.1
     thunderbolt.age=thunderbolt.age-p.att_pow
     if (thunderbolt.age==0) then
      if (thunderbolt.radius==8) then
        create_thunderbolt(thunderbolt.x,thunderbolt.y, thunderbolt.dx, -1, 1, 4)
        create_thunderbolt(thunderbolt.x,thunderbolt.y, -thunderbolt.dx, -1, 1, 4)
      end
      del(thunderbolts,thunderbolt)
      time_since_last_thunderbolt_was_deleted=0
     end   
     thunderbolt.dy=-2
     create_explosion(thunderbolt.x,thunderbolt.y)
     del(rockets,rocket)
     time_since_last_thunderbolt=0
     if (rnd(10)<=8) then create_powerup(thunderbolt.x,thunderbolt.y,1) end
    end
   end
  end
 end
end

function check_collision_rocket_vs_boss()
 if count(rockets) > 0 then
   for rocket in all(rockets) do
    if collide(rocket,boss) then
     create_firework(rocket.x,rocket.y)
     del(rockets,rocket)
     sfx(17)
     get_moving(boss)
     boss.flashing_timer=30
     boss.lives-=p.att_pow
     shake+=0.1
     if boss.lives<20 then
      time_between_ts=120
     elseif boss.lives<30 then
      time_between_ts=180
     end
     if boss.lives==0 then
       boss.state="laughing"
       reset_thunderbolts()
       create_powerup(boss.x,boss.y,flr(rnd(4)+2))
       create_powerup(boss.x,boss.y,flr(rnd(4)+2))
       create_powerup(boss.x,boss.y,flr(rnd(4)+2))
       scene.cycle(3)
     end
    end
   end
 end
end

function check_collision_thunderbolt_vs_player()
 for thunderbolt in all(thunderbolts) do
  if collide(thunderbolt,p) and p.state!=("electric") and p.flashing_timer==0 then
     -- del(thunderbolts,thunderbolt)
     player_hit()
  end
 end
end

function check_collision_thunderstrike_vs_player()
 for ts in all(thunderstrikes) do
  if collide(ts,p) and ts.t>60 and p.state!=("electric") and p.flashing_timer==0 then
    player_hit()
  end
 end
end

function check_collision_player_vs_powerup()
 for powerup in all(powerups) do
  if collide(powerup,p) then
     create_popup(p.x,p.y,powerup.type)
     if (powerup.type=="extra life") then
       p.lives=p.lives+1
       sfx(sfx_extra_life)
     elseif (powerup.type=="freeze") then
      freeze_timer=80
      music(-1, 200)
      sfx(-1, 1)
      sfx(-1, 2)
      sfx(-1, 3)
      sfx(-1, 4)
      sfx(16)
     elseif (powerup.type=="double freeze") then
      freeze_timer=160
      music(-1, 200)
      sfx(-1, 1)
      sfx(-1, 2)
      sfx(-1, 3)
      sfx(-1, 4)
      sfx(16)  
     elseif (powerup.type=="bomb blast") then
      create_explosion(boss.x,boss.y)
      boss.flashing_timer=30
      boss.lives-=5
      sfx(sfx_bomb)
      for thunderbolt in all(thunderbolts) do
       create_explosion(thunderbolt.x,thunderbolt.y)
       create_explosion(thunderbolt.x-rnd(2),thunderbolt.y+rnd(2))
       create_explosion(thunderbolt.x+rnd(3),thunderbolt.y-rnd(3))
       del(thunderbolts,thunderbolt)
      end
      shake+=2
     elseif (powerup.type=="rocket storm") then
      sfx(sfx_pickup_powerup)
      p.shoot_count=0
      p.attack=powerup.type
     elseif (powerup.type=="double damage") then
      sfx(sfx_pickup_powerup)
      p.shoot_count=0
      p.attack=powerup.type
      p.att_pow=2
     else
       sfx(sfx_pickup_powerup)
       score=score+powerup.score
     end
     del(powerups,powerup)
  end
 end
end

function isflashing(thing)
  if (thing.flashing_timer>0) and (abs(t % 12) < 6) then
    thing.flashing_timer=thing.flashing_timer-1
    return true
  else
    return false
  end
end
-->8
--rockets and power-ups

function create_rocket()
 local rocket_sprite=53
 if p.attack=="double damage" then
  rocket_sprite=54
 end 
 local rocket={
  sp=rocket_sprite,
  x=p.x+2,
  y=p.y,
  dx=0,
  dy=-3.8,
  ddy=0.06,
  hitbox={x=2,y=0,w=4,h=8},
  fire={}
 }
 add(rockets,rocket)
 sfx(sfx_rocket)
end

function create_rocket_storm()
 for i=1, 3 do
  local rocket={
   sp=48,
   x=p.x+2+rnd(16)-8,
   y=p.y-8+rnd(16)-8,
   dx=(rnd(2)-1)/3,
   dy=-2.3,
   ddy=0.0,
   hitbox={x=2,y=0,w=4,h=8},
   fire={},
  }
  add(rockets,rocket)
 end
 sfx(sfx_rocket_storm)
end

function max_number_of_rockets()
 if p.attack=="rocket storm" then
  return 2
 else
  return 1
 end
end

function shoot_rocket()
  if btnp(5) and p.state!="electric" and #rockets<=max_number_of_rockets() then
   p.shoot_count+=1
   if p.attack=="rocket storm" and p.shoot_count>5 then
    p.attack="regular"
    p.shoot_count=0
   end
   if p.attack=="double damage" and p.shoot_count>10 then
    p.attack="regular"
    p.att_pow=1
    p.shoot_count=0
   end
   
   if p.attack=="rocket storm" then
    create_rocket_storm()
   else
    create_rocket()
   end
  end
  -- if (btn(5)) btn_counter+=1
  -- if (not btn(5)) btn_counter=0
  -- if (btn_counter>60) then p.flashing_timer=60 end
end

function update_rockets()
 for r in all(rockets) do
  if (r.sp==48) and (t%20==0) then
   r.sp=49
  elseif (r.sp==49) and (t%20==0) then
   r.sp=48
  end
  r.dy+=r.ddy
  r.x+=r.dx+wind.dx*0.4
  r.y+=r.dy
  create_smoke(r.x,r.y,0.2,0.3+rnd(1),1)
  add(r.fire,{x=r.x+3,y=r.y+9})
  srand(p.f)
  for i=1,count(r.fire) do
    local fire=r.fire[i]
    fire.x+=(rnd(2)-1)
    fire.y+=(rnd(2)-1)
  end
  if count(r.fire)>10 then
    del(r.fire[1])
  end
  if r.y < -32 then
   del(rockets,r)
  end
  if r.dy > 0 then
   create_firework(r.x,r.y)
   del(rockets,r)
  end
 end
end

function draw_rockets()
  for r in all(rockets) do
   spr(r.sp,r.x,r.y)
   --  this part just draw the hitboxm used to test
   --  rect(r.x+r.hitbox.x,r.y+r.hitbox.y,r.x+r.hitbox.x+r.hitbox.w,r.y+r.hitbox.y+r.hitbox.h,2)
   --  rectfill(r.box.x1,r.box.y1,r.box.x2,r.box.y2,4)
   local colors={10,9,8,2}
   local c=count(r.fire)
   for i=1,c do
     local fire=r.fire[i]
     local col=colors[flr(4*(1-i/c))+1]
     pset(fire.x,fire.y,col)
   end
  end
end

function get_powerup_type()
  -- srand(t)
  local random=flr(rnd(7))
  if random==0 or boss.lives==0 then
   return "yummy"
  elseif random==1 then
   return "double freeze"
  elseif random==2 then
   return "bomb blast"
  elseif random==3 then
   return "rocket storm"
  elseif random==4 then
   return "freeze"
  elseif random==5 then
   return "double damage"
  elseif random==6 then
   if p.lives>2 then
    return "yummy"
   else
    return "extra life"
   end
  end
end

function get_powerup_sprite(type)
 if type=="extra life" then
  return 51
 elseif type=="double freeze" then
  return 43
 elseif type=="bomb blast" then
  return 44
 elseif type=="rocket storm" then
  return 42
 elseif type=="freeze" then
  return 40
 elseif type=="double damage" then
  return 45
 elseif type=="yummy" then
  if boss.lives==0 then
   return 60+flr(rnd(3))
  else
   return 41
  end
 end
end

function create_powerup(x,y,quantity)
  local type = get_powerup_type()
  local sprite = get_powerup_sprite(type)
  for i=1, quantity do
    local powerup = {
      x=quantity>1 and 8+rnd(120) or x,
      y=quantity>1 and 8+rnd(16) or y,
      dy=-1.6,
      ddy=0.1,
      age=0,
      lifespan=120,
      type=type,
      score=20,
      sprite=sprite,
      flashing_timer=0,
      hitbox={x=0,y=0,w=8,h=8},
    }
    add(powerups, powerup)
  end
  sfx(sfx_create_powerup)
end

function update_powerups()
 for powerup in all(powerups) do
   powerup.age+=1
   powerup.dy += powerup.ddy
   powerup.y += powerup.dy
   if powerup.y > 120 then
     powerup.dy=0
     powerup.y=120
   end
   if powerup.age==180 then
     powerup.flashing_timer=60
   end
   if powerup.age>=240 then
     del(powerups,powerup)
   end
 end
end

function draw_powerups()
  for powerup in all(powerups) do
    if (isflashing(powerup)) then
    else
      spr(powerup.sprite,powerup.x,powerup.y)
    end
  end
  pal()
end

function get_length_in_px(string)
 return (#string)*4
end

function create_popup(x,y,type)
 local popup = {
   x=x,
   y=y,
   dy=-0.30,
   t=0,
   life=70,
   copy=type,
   length=get_length_in_px(type)
 }
 add(popups, popup)
end

function update_popups()
  for popup in all(popups) do
    popup.y += popup.dy
    popup.t += 1
    if popup.t == popup.life then
      del(popups,popup)
    end
  end
end

function draw_popups()
 for popup in all(popups) do
  local c = 2
  for i=0,1 do
    if i==1 then
     c=t%4<2 and 10 or 14
    end
   print(popup.copy,popup.x+8-(popup.length/2)+i,popup.y+i,c)
  end
 end
end
-->8
-- thunderbolts

function create_thunderbolt(x,y,dx,dy,age,radius)
 local thunderbolt={
  t=0,
  x=x,
  y=y,
  dx=dx,
  dy=dy,
  age=age,
  radius=radius,
  state="falling",
  hitbox={x=0-radius,y=0-radius,w=radius*2,h=radius*2}
 }
 if t%2 == 0 then thunderbolt.dx=-thunderbolt.dx end
 add(thunderbolts,thunderbolt)
end

function shoot_thunderbolt()
 for i=1, 1 do
    local x = 16+rnd(96)
    local y = 0
    local dx = 0
    local dy = 2
    local age = 2
    local radius = 8
    create_thunderbolt(x,y,dx,dy,age,radius)
    sfx(sfx_thunder)
 end
 thunder=8
 time_since_last_thunderbolt_was_created=0
end

function update_thunderbolts()
 local delay=rnd(240)+240
 time_since_last_thunderbolt_was_created+=1
 time_since_last_thunderbolt_was_deleted+=1

 thunder=thunder-1
 if (thunder<0) then thunder=0 end

 for tb in all(thunderbolts) do
  tb.t+=1
  if tb.t >= 20 then
   tb.x+=tb.dx
   tb.y+=tb.dy
   tb.dy+=0.1
  end

  -- bouning off left and right screen border
  if tb.x<=0+tb.radius then
   tb.dx=-tb.dx
  elseif tb.x>=128-tb.radius then
   tb.dx=-tb.dx
  end

  -- bouning off bottom screen border
  if tb.y > 128-tb.radius then
   if (tb.state=="falling") then
    tb.state="bouncing"
    if tb.radius == 8 then
     tb.dx=(t%2==0 and 1 or -1)
    else
     tb.dx=tb.dx
    end
   end
   if tb.radius == 4 then
    tb.dy=-2.9
   else
    tb.dy=-3.6
   end
   create_splash(tb.x,tb.y)
   sfx(sfx_bounce)
  end
 end

 if scene.active==1 and t>60 then
  if boss.lives<15 then
   if #thunderbolts<2
    and time_since_last_thunderbolt_was_deleted>delay 
    and time_since_last_thunderbolt_was_created>60 then
    shoot_thunderbolt()
   end
  else
   if #thunderbolts<1
    and time_since_last_thunderbolt_was_deleted>delay 
    and time_since_last_thunderbolt_was_created>60 then
    shoot_thunderbolt()
   end
  end
 end

end

function draw_thunderbolts()
  for tb in all(thunderbolts) do
   if (tb.t < 20 and tb.radius == 8) then
    if tb.t%4==0 then
     circfill(tb.x,tb.y,20,7)
    end
   else
    if (tb.t%6==0) or (tb.t%6==1) then
      circ(tb.x,tb.y,tb.radius,12)
      circfill(tb.x,tb.y,tb.radius-1,7)
    elseif (tb.t%6==2) or (tb.t%6==3) then
      circfill(tb.x,tb.y,tb.radius-1,7)
    else
      circ(tb.x,tb.y,tb.radius,12)
    end
   end
  end
end

-->8
-- thunderstrike

function create_thunderstrike(x,y,age)
 local thunderstrike={
  t=0,
  x=x,
  y=y,
  age=120,
  hitbox={x=-3,y=0,w=4,h=127}
 }
 add(thunderstrikes,thunderstrike)
end


function update_thunderstrikes()
 if scene.active==1 and t>90 then 
  if t%time_between_ts==0 then
   create_thunderstrike(rnd(100)+10,0,120)
   sfx(sfx_thunderstrike)
  end
 end

 for ts in all(thunderstrikes) do
  ts.t+=1
  if ts.t==40 then
   shake+=0.1
   create_splash(ts.x,ts.y+128)
  end
  if ts.t==ts.age then
   del(thunderstrikes, ts)
  end
 end
end

function draw_thunderstrikes()
 for ts in all(thunderstrikes) do

 -- rect(ts.x+ts.hitbox.x,ts.y,ts.x+ts.hitbox.w,ts.y+ts.hitbox.h,8)

  if ts.t >= 0 and ts.t < 5 then
   line(ts.x+4,ts.y+40,ts.x+4,ts.y+40,7)
   line(ts.x-1,ts.y+46,ts.x-1,ts.y+46,7)
   line(ts.x-3,ts.y+50,ts.x-3,ts.y+50,15)
   line(ts.x,ts.y+58,ts.x,ts.y+58,7)
 		line(ts.x,ts.y+90,ts.x,ts.y+90,7)
   line(ts.x+5,ts.y+96,ts.x+5,ts.y+90,7)
   line(ts.x,ts.y+102,ts.x,ts.y+102,15)
   line(ts.x+2,ts.y+106,ts.x+2,ts.y+106,7)
  end

  if ts.t >= 10 and ts.t < 15 then
   line(ts.x+2,ts.y+40,ts.x+2,ts.y+40,7)
   line(ts.x,ts.y+48,ts.x,ts.y+48,7)
   line(ts.x-2,ts.y+52,ts.x-2,ts.y+52,15)
   line(ts.x,ts.y+62,ts.x,ts.y+62,7)
 		line(ts.x+1,ts.y+91,ts.x+1,ts.y+91,7)
   line(ts.x+2,ts.y+96,ts.x+2,ts.y+96,7)
   line(ts.x,ts.y+100,ts.x,ts.y+100,15)
   line(ts.x+2,ts.y+104,ts.x+2,ts.y+104,7)
  end

  if ts.t >= 20 and ts.t < 25 then
   line(ts.x,ts.y+40,ts.x,ts.y+41,7)
   line(ts.x,ts.y+50,ts.x,ts.y+50,7)
   line(ts.x,ts.y+60,ts.x,ts.y+61,7)
   line(ts.x,ts.y+70,ts.x,ts.y+70,7)
   line(ts.x,ts.y+77,ts.x,ts.y+77,7)
   line(ts.x,ts.y+89,ts.x,ts.y+89,7)
   line(ts.x,ts.y+96,ts.x,ts.y+96,7)
   line(ts.x,ts.y+116,ts.x,ts.y+116,7)
  end
  if ts.t >= 25 and ts.t < 30 then
   line(ts.x,ts.y+39,ts.x,ts.y+40,7)
   line(ts.x,ts.y+50,ts.x,ts.y+52,7)
   line(ts.x,ts.y+60,ts.x,ts.y+62,7)
   line(ts.x,ts.y+69,ts.x,ts.y+70,7)
   line(ts.x,ts.y+77,ts.x,ts.y+78,7)
   line(ts.x,ts.y+89,ts.x,ts.y+91,7)
   line(ts.x,ts.y+96,ts.x,ts.y+97,7)
   line(ts.x,ts.y+116,ts.x,ts.y+117,7)
  end
  if ts.t >= 30 and ts.t < 35 then
   line(ts.x,ts.y,ts.x,ts.y+128,7)
  end
  if ts.t >= 35 and ts.t < 40 then
   line(ts.x-2,ts.y,ts.x-2,ts.y+128,12)
   line(ts.x-1,ts.y,ts.x-1,ts.y+128,7)
   line(ts.x,ts.y,ts.x,ts.y+128,7)
   line(ts.x+1,ts.y,ts.x+1,ts.y+128,7)
   line(ts.x+2,ts.y,ts.x+2,ts.y+128,12)
  end
  if ts.t >= 40 and ts.t < 45 then
   line(ts.x,ts.y,ts.x,ts.y+128,7)
  end
  if ts.t >= 45 and ts.t < 50 then
   line(ts.x-2,ts.y,ts.x-2,ts.y+128,12)
   line(ts.x-1,ts.y,ts.x-1,ts.y+128,7)
   line(ts.x,ts.y,ts.x,ts.y+128,7)
   line(ts.x+1,ts.y,ts.x+1,ts.y+128,7)
   line(ts.x+2,ts.y,ts.x+2,ts.y+128,12)
  end
  if ts.t >= 50 and ts.t < 55 then
   line(ts.x,ts.y,ts.x,ts.y+128,7)
  end
  if ts.t >= 55 and ts.t < 60 then
   line(ts.x-2,ts.y,ts.x-2,ts.y+128,12)
   line(ts.x-1,ts.y,ts.x-1,ts.y+128,7)
   line(ts.x,ts.y,ts.x,ts.y+128,7)
   line(ts.x+1,ts.y,ts.x+1,ts.y+128,7)
   line(ts.x+2,ts.y,ts.x+2,ts.y+128,12)
  end
  if ts.t >= 60 and ts.t < 65 then
   rectfill(ts.x-6,ts.y,ts.x+6,ts.y+128,0)
  end
  if ts.t >= 65 and ts.t < 70 then
   rectfill(ts.x-6,ts.y,ts.x+6,ts.y+128,12)
   rectfill(ts.x-5,ts.y,ts.x+5,ts.y+128,7)
  end
  if ts.t >= 70 and ts.t < 75 then
   rectfill(ts.x-5,ts.y,ts.x+5,ts.y+128,12)
   rectfill(ts.x-4,ts.y,ts.x+4,ts.y+128,7)
  end
    if ts.t >= 75 and ts.t < 80 then
   rectfill(ts.x-6,ts.y,ts.x+6,ts.y+128,12)
   rectfill(ts.x-5,ts.y,ts.x+5,ts.y+128,7)
  end
  if ts.t >= 80 and ts.t < 85 then
   rectfill(ts.x-5,ts.y,ts.x+5,ts.y+128,12)
   rectfill(ts.x-4,ts.y,ts.x+4,ts.y+128,7)
  end
  if ts.t >= 85 and ts.t < 90 then
   rectfill(ts.x-6,ts.y,ts.x+6,ts.y+128,12)
   rectfill(ts.x-5,ts.y,ts.x+5,ts.y+128,7)
  end
  if ts.t >= 90 and ts.t < 95 then
   rectfill(ts.x-5,ts.y,ts.x+5,ts.y+128,12)
   rectfill(ts.x-4,ts.y,ts.x+4,ts.y+128,7)
  end
  if ts.t >= 95 and ts.t < 100 then
   rectfill(ts.x-6,ts.y,ts.x+6,ts.y+128,12)
   rectfill(ts.x-5,ts.y,ts.x+5,ts.y+128,7)
  end
  if ts.t >= 100 and ts.t < 105 then
   rectfill(ts.x-5,ts.y,ts.x+5,ts.y+128,12)
   rectfill(ts.x-4,ts.y,ts.x+4,ts.y+128,7)
  end
    if ts.t >= 105 and ts.t < 110 then
   rectfill(ts.x-6,ts.y,ts.x+6,ts.y+128,12)
   rectfill(ts.x-5,ts.y,ts.x+5,ts.y+128,7)
  end
  if ts.t >= 110 and ts.t < 115 then
   rectfill(ts.x-5,ts.y,ts.x+5,ts.y+128,12)
   rectfill(ts.x-4,ts.y,ts.x+4,ts.y+128,7)
  end
  if ts.t >= 115 and ts.t < 120 then
   line(ts.x+2,ts.y+40,ts.x+2,ts.y+40,7)
   line(ts.x,ts.y+48,ts.x,ts.y+48,7)
   line(ts.x-2,ts.y+52,ts.x-2,ts.y+52,15)
   line(ts.x,ts.y+62,ts.x,ts.y+62,7)
 		line(ts.x+1,ts.y+91,ts.x+1,ts.y+91,7)
   line(ts.x+2,ts.y+96,ts.x+2,ts.y+96,7)
   line(ts.x,ts.y+100,ts.x,ts.y+100,15)
   line(ts.x+2,ts.y+104,ts.x+2,ts.y+104,7)
  end
  
 -- if ts.t >= 115 and ts.t < 120 then
 --  line(ts.x,ts.y,ts.x,ts.y+128,7)
 -- end
  

 end
end
__gfx__
000000000000000000000000e0000000000000000000000000000000e00000000000000c7c00000000000000000000000000000000000000c0000000e0000000
00000000e0000000000000eeeee0000000000000e0000000000000eeeee0000000000c77577c00000000000070000000c0000000e0000000000000eeeee00000
000000eeeee000000000eee16e1ee000000000eeeee00c000000eee16e1ee00c700c775555577c000c000077e770000c006000eeeee000000000eefeeefee000
00c0eef61e61e000000efe777776ee000000ee16e1fee000000efe777776ee0000c75567776557c000707767e76770700000eefeeefee000060efee771e71e00
000efe777777ee0000efee677777efe0000efe777777ee0000efee677777eee0007567d171d765700007fe71777ee700000efee771e71e0000efee7777777ee0
00efee677777efe000eeeee67e76eee000efee677777efe000eeeee67e76efe00c7577557557757c007fee77717efe7060efee7777777ee060eeeee777e77fe0
00eeeee67e76eee00efeeeeeeeeeeeee00eeeee67e76eee00efeeeeeeeeeeeee0a5677667667765a007eee67776eef7000eeeee777e77fe00eeeeeeeeeeeeeee
0efeeeeeeeeeeeee0eeeee22222eeeee0efeeeeeeeeeeeee0eeeee22222eeeee075777777777775707feeeeeeeeeeee70eeeeeeeeeeeeeee0eeee22222eeeeee
0eeeee22222eeeee0e22e2222222e22e0eeeee22222eeeee0e22e2222222e22e075776167616775707eeee22222eeee70eeeee22222eeeee0e2e2222222e22ee
0e22e2222222e22e0e222222e222222e0e22e2222222e22e0e222222e222222e07566151115166570722e2222222e2270e22e2222222e22eee222222e222222e
0e222222e222222e02022222e22222020e222222e222222e02022222e222220207711777777711770772222222222277ee222222e22222e222222222e2222020
02022222e222220200000200e002000002022222e222c20200000200e00200000ac77700700777ca0c0772772772770c00022222e222220000020000e2000000
0c000200e002000000000000e000000000000200e002000000000000e0000000000000007000000000c00700700700c000002000e02000000000000e00000000
00000000e000000000000000e000000000000000e000000000000000e000c00000000000700c00000000000070000000c0000000e00000000000e00e00000000
00000e00e00c0c000c000e00e0000000c0c00e00e000000000000e00e0000000000c070070000000000000007000000000000e00e0000000c0000ee000000000
000000ee0000c000000000ee00000000000000ee00000000000000ee0000000000000077000000000000007700000000000000ee000000000000000000000000
d0000000000000000000000000000000000000000000000000000000000000000078e0660088bb0b0888888004400440001111a0000000000000000000000000
ddd0000000000000d000000000000000d000000000000000000000000000000007788760087e88b088288288447444700555597a0770a0770000000000000000
d66ddd0000000000ddd0000000000000dd0000000000000000000000000000007f777ff70788bb8b89a22a784492449056d558950778a8770000000000000000
d67666ddddddd000d67ddd0000000000dddd00000000000000000000000000007ffff447e98ebb8b899aa978444244405d555551007696700000000000000000
0d7777666666d0000d7766ddddddd0000d77dd0000ddd00000511680000ddd0007444470888988882779977244424442555551d1000d0d000000000000000000
0d677777777d00000d677766776d00000d6776dddddd000000051100005117800072260088888842299aaa724444444415551d51006aa9d00000000000000000
00dd67776dd0000000dd67776dd0000000dd67776dd000000000000000511200000760008988842099adda79055005500111d510000111000000000000000000
0000ddddd00000000000ddddd00000000000ddddd00000000000000000000000007776000884200009aaaa900ff00ff000111100000090000000000000000000
0001e1000001e100000000000e800e800ee0ee000000e0000000e00000000000000000000000000000000000000000000000000000999900000fe77000000000
000878000008780000000000e7f8efe8e7feeee000088e0000088e00000000000000000000000000000000000000000000000000099999900078877700000000
000a7f000007af0000000000efeefeeeefeeee80000888000008880000000000000000000000000000000000000000007828888799bbbb990777777700000000
000a7a00000a7a0000000000eeeeeee80eeee82000826f80008478800000000000000000000000000000000000000000788882879b4b88397777777700000000
009aa9400009a900000000000eeeee8200ee82000006f70000078e00000000000000000000000000000000000000000078808827b444888b4ff44ff400000000
009a99400009a9000000000000eeee2000082000000677000008e600000000000000c00000c000c00000000000000000b788827b4aaaaaa8f44ff44f00000000
099a49440099a42000000000000ee2000000000000067700000e78000000c0000000c00000cc0cc000c000c0000000003b7767b3aaaaaaaa4444444400000000
000aa900000aa90000000000000020000000000000040000000400000000c000000ccc000000d0000c00000c0c00000c03bb3b3099999999f777777f00000000
11111111111111111101111111111111111111110011110011111111111111111111000000000000000000000000000000000000000000000000000000000000
11111111011111111000011110011111111111110000000011111111110111111110000000000000000000000000000000000000000000000000000000000000
11111111000111100000000000111111111111110000000011111111111001111000000000000000e00000000000000000000000000000000000000000000000
111111110000000000000000000111111111011100000000111011111111000000000000c00000eeeee000000000000000000000000000000000000000000000
1111111100000000000000000001111111111011000000001100001111000000000000000000eee22e22e0000000000000000000000000000000000000000000
111111110000000000000000000011111111001100000000110000000000000000000000000eee2eeeee2e000000000000000000000000000000000000000000
11111111000000000000000000000011110000010000000010000000000000000000000000e7eeeeeeeeeee00000000000000000000000000000000000000000
11111111000000000000000000000000000000000000000000000000000000000000000000eeeeeeeeeeeef00000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000efeeeeeeeeeeeee0000000000000000000000000000000000000000
0000000000000000000000000000000000500000000000000000000000000000000000000eeeee22222eeeee0000000000000000000000000000000000000000
0000000000000000005000000000000000d50000000000500000000000000000000000000e22e2222222e22e0000000000000000000000000000000000000000
000000000000000000d0000000000500005d000000000d000000000000000000000000000e222222e222222e0000000000000000000000000000000000000000
0005000000005000000d00000000d000000dd0000000d00000000000000000000000000002022222e22222020000000000000000000000000000000000000000
0000dd0000dd00000000dd0000dd00000000dd5000dd000000000000000000000000000000000200e00200000000000000000000000000000000000000000000
000000dddd000000000000dddd000000000000dddd00000000000000000000000000000000000e00e00000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000c0000ee00c000c00000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000e000000000000000e000000000000000e0000000000000000e0000000000000000000000000000000000000000000000000000000000000000000000
0000000eee00000000000000e000000000000000e0000000000000000e0000000000000000000000000007000000000000070000000000000000070000070000
00000eeeeeee00000000000eee00000000000002e200000000000000ee0000000000000000000000000000000000007000000000000070000070000000000000
0000efe171eee000000c00e676e000000000000eee00000000000000e20000000000000000000000000c000c0000000000000c000c000000000000000c000c00
000efe77777efe00000000e171e00c0000cc000eee0000000000000ee000000000000000000000000000c7c0000a0000000000c7a000000000000a0000c7c000
000eee67776eee0000000e67776e00000cccc00eee000ccc0000000ee000000000007000000700000700777000a7a0000000007a7a0000000000a7a000777000
00eeeeeeeeeeeee000000eeeeeee00000cc0002eee2000ccc00000ee2000000000000000007770000000c7c00a777a00000000a777a00000000a777a00c7c000
00eeee22222eeee00000eee222eee000000000eeeee00000c0c000ee0000000c0000000000070000000c000c00a7a00000700c0a7a0000000000a7a00c000c00
00e2e2222222e2e00000ee22222ee000000000eeeee00000000000ee00000000000000000000000000000000000a000000000000a000070000000a0000000000
00e22222e22222e0000ee222e222ee00000000eeeee0000000000ee20000000000000000000000000000000000000000c0000000000000000000000000070000
00e22222e22222e0000e2222e2222e00000000e2e2e0000000000ee000000000c0000000000000000c0000000000007000000000000000000000000000000000
00200200e0020020000e0200e0020e0000000002e20000000000eee00000000000e000000000000000e000000000000000e000000000000000e0000000000000
00000000e000000000000000e000000000000000e000000000e00e20000000000e00eeeeeef000000e00feeeeef000000e00eeeffe0000000e00feeeeef00000
00000e00e000000000000e00e000000000000e00e000000000e00e0000000000020022eeeeeef00002002eeeeeeef000020022eeeeee000002002eeeeeeef000
000000ee00000000000000ee00000000000000ee00000000000ee000000000000022eeeeeeeeeeee0022eeeeeeeeeeee0022eeeeeeeeeee00022eeeeeeeeeeee
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07eeee00000007ee0e00000007eee000000007eee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0eeeee07ee0e0eee0e07eee00eeede07eeee0eeede00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0deeed0eee0e0eee0e0eeede0eee0e0eeeee0eee0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00eee00eee0e0eee0e0eee0e0eee0e0eeeee0eee0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00eee00eee0e0eee0e0eee0e0eee0e0eeedd0eeeed00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00eee00eeeee0eeeee0eee0e0eee0e0eeee00eeede00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00eee00eee0e0deeed0eee0e0eeeed0eeed00eee0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ddd00eee0e00ddd00eee0e0dddd00eeeee0ddd0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000ddd0d0000000ddd0d0000000ddddd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000007eeee00000007ee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007eee00eeeee07ee000eee00007ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000eeeee0eeeee0eee000eee000eeede00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000eeeee0eeedd0eee000eee000eee0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000eee0e0eeee00eee000eee000eee0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000eeeed0eeed00eee000eee000eeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000eee0e0eeeee0eee000eeeee0eeede00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000eeeed0ddddd0eeeee0ddddd0eee0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000dddd00000000ddddd0000000ddd0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1d1d1ddd111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1d1d1d1d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111ee1ee111ee1ee111ee1ee11
1ddd1ddd111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111e7feeee1e7feeee1e7feeee1
111d111d11111111111111111111111111111111111111111111111111111e111111111111111111111111111111111111111111efeeee81efeeee81efeeee81
111d111d111111111111111111111111111111111111111111111111111188e111111111111111111111111111111111111111111eeee8211eeee8211eeee821
1111111111111111111111111111111111111111111111111111111111118881111111111111111111111111111111111111111111ee821111ee821111ee8211
11111111111111111111111111111111111111111111111111111111111826f81111111111111111111111111111111111111111111821111118211111182111
1111111111111111111111111111111111111111111111111111111111116f711111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111167711111111111111111111111111111111111111111111111111111111111111111
11111111111111111d111111111111111111111111111111d1111111111167711111111111111111111111111111111111111111111111111111111111111111
11111111111111111ddd11111111111111111111111111ddd1111111111141111111111111111111111111111111111111111111111111111111111111111111
11111111111111111d67ddd11111111111111111111ddd76d1111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111d7766ddddddd111111ddddddddd77d1111111111111a111111111111111111111111111111111111111111111111111111111111111111
111111111111111111d677511786d11111111d677511786d11111111111111a11111111111111111111111111111111111111111111111111111111111111111
1111111111111111111dd65112dd1111111111dd65112dd11111111111111aa11111111111111111111111111111111111111111111111111111111111111111
111111111111111111111ddddd11111111111111ddddd111111111111111111a111a111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111151111111111111111111111111111111111111111111111666111111111111111111111111111111111111111111111111111111111151111111
111111111111d1111111111511111111111111111111111111111111116666611111111111a111111111111111111111111111111111111111111111d1111111
1111111111111d11111111d1111111111111111111111111111111111a6666a1111111111111111111111111111111111111111111111111111111111d111111
11111115111111dd1111dd1111111111111111111111111111111111116666611191111191111111111111111111111111111111111111511111111111dd1111
111111d111111111dddd1111111111111111111111111111111111111116661111a1111111111111111151111111111111111111111111d1111111111511dddd
1111dd111111111111111511111111111111115111111111111111111111111111111191111111111111d11111111115111111111111111d11111111d1111111
dddd11111111111111111d1111111111511111d1111111111511111111611111111111111111111111111d11111111d11111111111111111dd1111dd11111111
1111111111111111111111d11111111d1111111d11111111d1111111166666611111111111111111111111dd1111dd11111111111111111111dddd1111111111
11111111111111111111111dd1111dd111111111dd1111dd1111111111666666111111111111111111111111dddd111111111111111111111111111111111111
1111111111111111111111111dddd1111111111111dddd1111111111111666661111111111111111111111111111111111111111111111111111111111111111
11111111151111111111111111111111111111111111111111111111111666661111111115111111111111111111111111511111111111111111111111111111
111111111d111111111151111111111111111111111111111511111111116666111111111d111111111151111111111111d11111111115111111111111111111
1111111111d11111111d11111111111111111111111111111d11111111115d6d1191111111d11111111d111111111111111d11111111d111111111111111dddd
d11111111dddd1111dd1111111111111111111111111111111d11111111d6dddd11111111dddd1111dd11111111111111111dd1111dd111111d11111111ddddd
ddd1111ddddddddddd111111111111111111111111111111111dd1111dd666ddddd1111ddddddddddd11111111111111111111dddd111111111dd1111ddddddd
ddddddddddddddddddd111111111d11111111111111d11111111dddddddd66dddddddaddddddddddddd111111111d11111111111111d11111111dddddddddddd
ddddddddddddddddddd1111111111d111111111111dddc1111dddddddddd666dddddddddddddddddddd1111111111d111111111111dddd1111dddddddddddddd
dddddddddddddddddddd11111111dd111111111111dddc777cdd8dddddddd6dddddddddddddddddddddd11111111dd111111111111dddddddddddddddddddddd
dddddddddddddddddddddd1111ddddc1111111111ddddc777cdddddddddddddddddddddddddddddddddddd1111ddddd1111111111cdddcdddddddddddddd1ddd
ddddddddd1ddddddddddddddddddddcd11111111dddddc777cddddd6dd9d6ddddddddddddddddddddddddddddddddddd11111111dddddcdddddddddddddddddd
dddddddddddddddddddddddddddddddddc1111dddddddc777cdddd666d6666dddddddddddddddddddddddddddddddddddd1111dddd1d1ddddddddddddddddddd
dddddddddddddddddddddddddddddddddcdddddddddddc777cddddd6d6666ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dd1dddddddddddddddddddddddddddddddddddddcddddc777cdddddd666ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddcddddc777cddddddd6ddddddddddddd9ddddddddddddddddddddddddddcddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cddddddddddddddddddddddddddddddddddddddddddddddddcddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd1dddddddddddddddddddddd1dd1ddddddddc777cddddddddddddddddddddddddddddddddddddddddddddcdddddd1ddddddddddddd1dddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddd9dddddddddddddddddddddddddddddddddcddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddd1dddddddddddddc777cddddddddddddddddd9dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddd1ddddddddddddcdddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddcdddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
d1dddddddddddddddddddddddddddddddddddddddddddc777cddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddcddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cddddddddd9ddddddddddddddddddddddddddd9ddddddddddd1ddddddddddddddddddddcddcdddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddcdddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddd2ddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddd1ddddddddddddd1dddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddd1ddddddddddd1dd1dddddddddddc777cddddddddddddddddddddddddddddddddddddddddddddddddddddddcddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddcdddddddddc7778dddddddddddddcddddddddddddddddddddddddddddddddddddddddcddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddcdddddddddc777cdddddddddddddcdddddddddddddddddddddddddddddd8dddddddddddd1dddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc77781ddddddddddddddddddddddddddddddddddddddddddddddddddddddddd1ddddddddddddddddddd
ddddddddddddddddddddddddddddddddddd1dddddddddc777cddddddddddddddddddddddd8dddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddcdddddddddddddddddddddddddddddddddc777cdddddd1ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddcdddddddddddddddddddddddddddddddddc779cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddd1dddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddd1ddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddd1ddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddd1ddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddd1dddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddd1ddddddddddddddddd1ddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cddddddddd8dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dd1dddddddddddddddddddddddddddd1dddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddcd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddd1dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddcd
dddddddddddddddddddddddddddddd1dddddcddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddd1dddddddddddddddddddddddddddddddcddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc787cddddddddddddddddddddddcddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddcddddddddddddddddddddddddddddddddddc777cddddddddddddddddddddddcddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddcddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddd1c777cdddddddddddddddddddd28dddd1ddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddd8ddddddddddddddddddddddddddddddddddddddddddd
ddddddddddd1dddddd1ddddddddddddddddddddddddddc777cddddddddddddddddddddddddddddddddddddd1dddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddddd8777cdddddddddddddddddddddddddddddddddddddddddd1ddddddddd1ddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddd2dddcdddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddcddd1dddddddddddddddcdddddc777cdddd2ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddcdddddddddddddddddddddddddc777cddddddddddddddddddddddddddddddddddddddddcddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cddddddddddddddddddddddddddddddddddddddddcddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddd2ddddddddddddddddddddddddddd
dddddddddddddddddddddd777ddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddd777ddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddd77777dddddddddddddddddddc777cddddddddddddddddddddddddd1dddddd1dd77777dddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddd17777777ddddddddddddddddddc777cdddddddddddddddddddddddddddddddddd7777777ddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddd7777777ddddddddddddddddddc777cdddddddddddddddddddddddddddddddddd7777777ddddd1ddddddddddddddddddddddddddddddd
dddddddddddddddddddd7777777ddddddddddddddddddc777cdddd1ddddddddddddddddddddddddddddd7777777ddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddd77777ddd1dddddddddddddddc777cddddddddddddd2ddddddddddddddddddddd77777dddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddd777ddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddd777ddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cddddddddddddddddddddddddddddddddddddddddddddd2dddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddd1ddddddcddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddcddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddd1ddddddddddddddddddddddc777cddddddddddddddddddddcddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cddddddddddddddddddddcddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddd8ddc777cddddddddddddddddddddddddddddddddd1ddddddddddddddddddddddddddddddddddddddd1dddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cddddddddddddddddddddddddddddddddddddd2dddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddcdddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddcdddddddddddddddddddddddddddddddddddddd
ddddddddddddddd1dddddddddddddddd1ddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cddddddddddddddddddddddddddddddddddddddddddddddddd1ddeddddddddddddddddddddddddd
dddddddddddd1ddddddddddddddddddddddddddddddddc777cddddddddddd1ddddddddddddddddddddddddddddddddddddddeeeeeddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cddddddddddddddddddddddd2ddddddddddddddddddddddcdeef61e61eddddddddddddddddddddd
dddddddddddddddddddddcdddddddddddddddddddddddc277cdddddddddddddddddddddddddddddddddddddddddddddddefe777777eedddddddddddddddddddd
dddddddddddddddddddddcdddddddddddddddddddddddc777cddddddddddddddddddddddddddddddddddddddddddddddefee677777efeddddddddddddddddddd
dddddddddddddddddddddd1ddddddddddddddddddddddc777cdddcddddddddddddddddddddddddddddddddddddddddddeeeee67e76eeeddddddddddddddddddd
dcdddddddddddddddddddddddddddddddddddddddddddc777cdddcdddddddddddddddddddddddddddddddddddddddddefeeeeeeeeeeeeedddddddddddddddddd
dcdddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddddddddddddddddddddddddddddddeeeee22222eeeeecddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cdddddddddddddddddd1dddddddddddddddddddddddddde22e2222222e22ecddddddddddddddddd
ddddddddddddddddddddddddddddddddddddddddddcddc777cddddddddddddddddddddddddddddddddddddddddddddde222222e222222edddddddddddd1ddddd
ddddddddddddddddddddddddddddddddddddddddddcddc777cddddddddddddddddddddddddddddddddddddddddddddc2d22222e22222d2dddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddc777cddddddddddddddddddddddddddddddddddddddddddddccddd2ddedd2dddddddddddddddddddddd
dddcdddcddccdddddddddddddddddddddddddcdddcdddc777cddddcdddddddddddddddddddddddddddddd1ddddddddddddcdddeddddddddcdddcdddddddddddd
dddcdddccdccddddddddddddcddddddddddcdccdccdddc777cddddcdddddddddddddddddddddddddddddddddddddddddddce1ceddcdcdddccdccdddddddcdddc
ddcccdddddccddddddddddddcddddddddddcdddddddddc777cdddcccddddddddddddddddddddddddddddddddddddddddddddeeddddcdddddddddddddddcddddd

__map__
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4142434440464748414243444046474800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000045000000000000004500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
001a071f0161105611096110f611126111361114611146111361112611116110f6110f6111061113611146111561117611176111761116611136111261111611116111061110611116111461117611196111a611
010600000e0751077513075187751a0751c7751f07524775126000e60013600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000015614136171d6141c614266142661426614266153260432605305000e7000c7000a700087000770006700057000470003700027000170001700017000170001700017000170001700017000170001700
0004000035663290531b6531b0531b0531264312043120430863308033080331f0030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0106000018064240641a054260541c044280441d034290341f0242b02408003017000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000e7710e7710e7710e7710e7710e7710e7710e7710c7710c7710a7710a7710877108771077710777105771057710476104761037510375101741017410173101731017210172101711017110171101711
01100000006770065700637006000750007600071001200000600006000060002600046000560007600096000e6000e6001060011600136000000000000000000000000000000000000000000000000000000000
000a0000110631d063230002300002000010040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000267102661026510264102630026200261002610026103700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008000002653166201e34616666213631664305623026110161101611016110161428300293002c3053f3033f303000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000307402d7401f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a00001154021540245401500020503000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800001c5601f560245602455024540245302452500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006000009213092230921108300092130922109210093010b2130e313107230b3130e3230b3330c321093040c323102330c721013050267702667026670c2400c2410c2410c2210c2310c2210c2310c22104111
00070000036750b671166510f541285311b521285211b521285111b511285110c6110561113701177051370510705137051770513705107051370517705137051070513705177051370510705137051770513705
01080000287612d7712d7612d7512d7411070513705107050c7051070513705107050c7051070513705107050c7051070513705107050c7051070513705107050c7051070513705107050c705107051370510705
000e00000277102771027710277102751027510275102751027310273102731027310e0001000011000130000c00013700100000e7000c0000000000000000000000000000000000000000000000000000000000
01040000104511c452104431c441104321c423284001c401284011c40128401000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001c7301f7511f7521f75110600136001360013600196001b6001e6002360028600326003a6003e6003c6053960535605316052d605266052060519605126050e6050b6050760505600046000460004600
000400000267102772233410267202771103320267102762043221a70500000307000c00000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011600000042500415094250a4250042500415094250a42500425094253f2050a42508425094250a425074250c4250a42503425004150c4250a42503425004150c42500415186150042502425024250342504425
001600000c0330c4130f54510545186150c0330f545105450c0330f5450c41310545115450f545105450c0230c0330c4131554516545186150c03315545165450c0330c5450f4130f4130e5450e5450f54510545
0116000005425054150e4250f42505425054150e4250f425054250e4253f2050f4250d4250e4250f4250c4250a4250a42513425144150a4250a42513425144150a42509415086150741007410074120441101411
011600000c0330c4131454515545186150c03314545155450c033145450c413155451654514545155450c0230c0330c413195451a545186150c033195451a5451a520195201852017522175220c033186150c033
010b00200c03324510245102451024512245122751127510186151841516215184150c0031841516215134150c033114151321516415182151b4151d215224151861524415222151e4151d2151c4151b21518415
00030000026700c6601a6500964009641096410e6610e661134411344110651106510a4410a441076310763103630036300363000000000000000000000000000000000000000000000000000000000000000000
__music__
00 14154040
02 16174040
00 14184058
02 16184040
00 40404040
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000


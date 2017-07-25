pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- thunder bella the cloud chaser by evil paper
-- by evilpaper, funky chiptune by ..

-- sfx
sfx_rain=0
sfx_game_on=1
sfx_game_over=2
sfx_p_stun=3
sfx_p_recover=4
sfx_p_knocked_down=5
sfx_thunder=6
sfx_bounce=7
sfx_fireworks=8
sfx_rocket=9
sfx_create_treat=10
sfx_eat_treat=11
sfx_extra_life=12

-- initialize game ------------
function _init()
 t = 0
 shake = 0
 time_since_last_thunderbolt=0
 max_number_of_thunderbolts=2
 time_to_next_thunderbolt=120

 boss = {
   x=51,
   y=6,
   t=0,
   lives=100,
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

 fireworks = {}
 p = {
   x=56,
   y=112,
   t=0,
   lives=3,
   sprite=0,
   direction=0,
   state="idle",
   hitbox={x=2,y=5,w=12,h=10},
   flashing_timer=0
  }

 popups = {}
 puffts = {}
 rain_fg = {}
 rain_bg = {}
 rockets = {}
 splashes = {}
 thunderbolts = {}
 treats = {}
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
   scene.cycle(1)
   sfx(sfx_game_on)
  end
end

scene.draw[0] = function()
  circfill(48,54+(flr(t/16)%2),8,1)
  circfill(68,60+(flr(t/16)%2),20,1)
  circfill(46,66+(flr(t/16)%2),10,1)
  circfill(84,58+(flr(t/16)%2),10,1)
  circfill(80,70+(flr(t/16)%2),10,1)
  circfill(58,72+(flr(t/16)%2),12,1)
  spr(192,44,54+(flr(t/16)%2),8,4)
  if (abs(t % 30) <= 20) print("press x to start", 4.5*8,11*9,7)
end
-------------------------------

-- game on scene specifics ----
scene.update[1] = function()
 shoot_thunderbolt()
 shoot_rocket()
 check_collision_rocket_vs_thunderbolt()
 check_collision_rocket_vs_boss()
 check_collision_thunderbolt_vs_player()
end
-------------------------------

-- game over scene specifics --
scene.update[2] = function()
  update_rockets()
  if t>60 and x_btn then
    sfx(sfx_game_on)
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
end
-------------------------------

-- helper functions -----------
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
     if (thunderbolt.age==0) then
      create_thunderbolt(thunderbolt.x,thunderbolt.y, 1, -1.6, 1, 4)
      create_thunderbolt(thunderbolt.x,thunderbolt.y, -1, -1.6, 1, 4)
     end
     del(thunderbolts,thunderbolt)
     del(rockets,rocket)
     time_since_last_thunderbolt=0
     if (flr(rnd(3))==0) then create_treat(thunderbolt.x,thunderbolt.y,1) end
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
     boss.flashing_timer=30
     boss.lives-=1
     if boss.lives==0 then
       boss.state="laughing"
       reset_thunderbolts()
       create_treat(boss.x,boss.y,flr(rnd(4)+4))
       scene.cycle(3)
     end
    end
   end
 end
end

function check_collision_thunderbolt_vs_player()
 for thunderbolt in all(thunderbolts) do
  if collide(thunderbolt,p) and p.state!=("electric") and p.flashing_timer==0 then
     del(thunderbolts,thunderbolt)
     player_hit()
  end
 end
end

function check_collision_player_vs_treat()
 for treat in all(treats) do
  if collide(treat,p) then
     create_popup(p.x,p.y)
     if (p.lives<3) then
       p.lives=p.lives+1
       sfx(sfx_extra_life)
     else
       sfx(sfx_eat_treat)
     end
     del(treats,treat)
  end
 end
end

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

function create_popup(x,y)
 local popup = {
   x=x,
   y=y,
   dy=-0.30,
   t=0,
   life=70,
   copy=get_popup_copy()
 }
 add(popups, popup)
end

function get_popup_copy()
  local copies = {"sweet","nice","awesome","yummy"}
  local index = 1+flr(rnd(4))
  local copy = copies[index]
  if (p.lives<3) then copy = "extra life!" end
  return copy
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

function create_rocket()
 local rocket={
  sp=53,
  x=p.x+2,
  y=p.y,
  dx=0,
  dy=-3,
  ddy=0.01,
  hitbox={x=2,y=0,w=4,h=8},
  fire={}
 }
 add(rockets,rocket)
 sfx(sfx_rocket)
end

function create_splash(x,y)
 sfx(sfx_bounce)
 for i=1, rnd(10)+6 do
  local splash = {
   x=x,
   y=y,
   dx=(rnd(2)-1),
   dy=-rnd(2)-0.25,
   r=(rnd(1)+0.50),
   colour=12
  }
  if splash.r <= 0.8 then splash.colour = 7 end
  add(splashes,splash)
 end
end

function create_thunderbolt(x,y,dx,dy,age,radius)
 local thunderbolt={
  t=0,
  sprite={48,49,50,51},
  x=x, -- 16+rnd(96)
  y=y, -- 18
  dx=dx,
  dy=dy,
  age=age,
  radius=radius,
  dy_bounce=-2.5-rnd(1),
  hitbox={x=0,y=0,w=radius*2-2,h=radius*2-2}
 }
 if t%2 == 0 then thunderbolt.dx=-thunderbolt.dx end
 add(thunderbolts,thunderbolt)
 sfx(sfx_thunder)
end

function create_treat(x,y,quantity)
  for i=1, quantity do
    local treat = {
      x=quantity>1 and 8+rnd(120) or x,
      y=quantity>1 and 8+rnd(16) or y,
      dy=-1.6,
      ddy=0.1,
      sprite=40+flr(rnd(4)),
      hitbox={x=0,y=0,w=8,h=8},
    }
    add(treats, treat)
  end
 sfx(sfx_create_treat)
end

function shoot_thunderbolt()
 if boss.lives < 90 then
   max_number_of_thunderbolts=3
   time_to_next_thunderbolt=100
 end
 if boss.lives < 80 then
  max_number_of_thunderbolts=4
  time_to_next_thunderbolt=90
 end
 if boss.lives < 70 then
   max_number_of_thunderbolts=5
   time_to_next_thunderbolt=80
 end
 if boss.lives < 60 then
   max_number_of_thunderbolts=6
   time_to_next_thunderbolt=70
 end

 if count(thunderbolts) < max_number_of_thunderbolts
  and time_since_last_thunderbolt > time_to_next_thunderbolt then
    local x = 16+rnd(96)
    local y = 18
    local dx = rnd(1.2)+0.4
    local dy = rnd(1.4)+0.4
    local age = 0
    local radius = 8
    create_thunderbolt(x,y, dx, dy, age, radius)
    time_since_last_thunderbolt=0
 end
 time_since_last_thunderbolt+=1
end

function shoot_rocket()
  if btnp(5) and p.state!="electric" then create_rocket() end
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
-------------------------------

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
   boss.y=10
  elseif (t%50<32) then
   cloud.y=-1
   cloud.sprite=82
   boss.y=8
  else
   cloud.y=-2
   cloud.sprite=84
   boss.y=6
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
   end
   p.age+=1
  end
 end
end

function update_rockets()
 for r in all(rockets) do
  r.dy+=r.ddy
  r.x+=wind.dx*0.4
  r.y+=r.dy
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
  if r.y < -10 then
   del(rockets,r)
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

function update_thunderbolts()
 for l in all(thunderbolts) do
  l.t+=1
  l.x+=l.dx
  l.y+=l.dy
  -- l.sp+=1

  --if l.sp==52 then
  -- l.sp=48
  --end

  -- animate(l)

  l.dy+=0.08

  if l.x<=0 then
   l.dx=-l.dx
  elseif l.x>=120 then
   l.dx=-l.dx
  end

  if l.y > 120 then
   l.dy=l.dy_bounce
   create_splash(l.x,l.y)
  end

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

function update_boss()
 if boss.state=="idle" then
    boss.left_pupil_sprite=39
    boss.right_pupil_sprite=39
    boss.dx=0
    boss.ddx=0
    boss.left_eye_sprite=get_boss_sprite("idle")
    boss.right_eye_sprite=get_boss_sprite("idle")
    if scene.active==1 and boss.t>30 then
      boss.destination=flr(4+rnd(80))
      boss.t=0
      boss.dx=0.4
      boss.ddx=0.05
      if boss.x > boss.destination then
        boss.dx=-boss.dx
        boss.ddx=-boss.ddx
      end
      boss.state="moving"
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

  boss.left_pupil_y=boss.y
  boss.right_pupil_y=boss.y
  boss.t+=1
  boss.x+=boss.dx
  boss.dx+=boss.ddx
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
   if p.x>128 and p.direction==1 then p.x=-20 end
   if p.x<-16 and p.direction==-1 then p.x=132 end
   -- if (x_btn) change_state(p,"shooting")
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

function update_treats()
 for treat in all(treats) do
   treat.dy += treat.ddy
   treat.y += treat.dy
   if treat.y > 120 then
     treat.dy=0
     treat.y=120
   end
 end
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

function _update60()
 t=t+1
 scene.updates()
 update_input()
 update_wind()
 update_player()
 update_clouds()
 update_boss()
 update_rain_fg()
 update_rain_bg()
 update_thunderbolts()
 update_puffts()
 update_splash()
 update_rockets()
 update_fireworks()
 update_popups()
 update_treats()
 check_collision_player_vs_treat()
end
-------------------------------

--- draw functions ------------
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
 local agemult=1
 agemult=(p.age-5)/p.maxage
 agemult=1-(agemult*agemult)
 agemult=mid(0,agemult,1)
 circfill(p.x,p.y,p.r*agemult,p.col)
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

function draw_player()
  if (isflashing(p)) then
    for i=1,15 do
      pal(i,7)
    end
  end
  spr(p.sprite,p.x,p.y,2,2,p.direction==-1)
  pal()
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

function draw_boss_eyes()
  spr(boss.left_eye_sprite,boss.x,boss.y,2,1)
  spr(boss.right_eye_sprite,boss.x+16,boss.y,2,1,true)
  spr(boss.left_pupil_sprite,boss.left_pupil_x,boss.left_pupil_y)
  spr(boss.right_pupil_sprite,boss.right_pupil_x,boss.right_pupil_y)
end

function isflashing(thing)
  if (thing.flashing_timer>0) and (abs(t % 12) < 6) then
    thing.flashing_timer=thing.flashing_timer-1
    return true
  else
    return false
  end
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

function draw_thunderbolts()
  for l in all(thunderbolts) do

   if (l.t == 1) then
    circfill(l.x,l.y,25,7)
   end

    if (t%6==0) or (t%6==1) then
      circ(l.x,l.y,l.radius,12)
      circfill(l.x,l.y,l.radius-1,7)
    elseif (t%6==2) or (t%6==3) then
      circfill(l.x,l.y,l.radius-1,7)
    else
      circ(l.x,l.y,l.radius,12)
    end
   -- spr(l.sprite[l.frame],l.x,l.y)

   -- spr(l.sp,l.x,l.y)
   --  this part just draw the hitbox, used to test
   --  rect(l.x+l.hitbox.x,l.y+l.hitbox.y,l.x+l.hitbox.x+l.hitbox.w,l.y+l.hitbox.y+l.hitbox.h,2)
   --  rectfill(l.box.x1,l.box.y1,l.box.x2,l.box.y2,3)
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

function draw_lives()
  for i=1,p.lives do
   spr(52,127-i*8,2)
  end
end

function draw_treats()
  for treat in all(treats) do
    spr(treat.sprite,treat.x,treat.y)
  end
end

function draw_cloud_lives()
  -- print(boss.lives,3,3,2)
  print(boss.lives,2,2,13)
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

function draw_popups()
 for popup in all(popups) do
  local c = 2
  for i=0,1 do
    if i==1 then
     c=t%4<2 and 10 or 14
    end
   print(popup.copy,popup.x+i,popup.y+i,c)
  end
 end
end

function _draw()
 rectfill(0,0,128,128,13)
 draw_background_rain()
 draw_foreground_rain()
 scene.drawing()
 draw_cloud()
 draw_boss()
 draw_thunderbolts()
 draw_splash()
 draw_player()
 draw_rockets()
 draw_fireworks()
 draw_lives()
 draw_cloud_lives()
 shake_screen()
 draw_popups()
 draw_treats()
end
-----------------------------
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
d0000000000000000000000000000000000000000000000000000000000000000078e0660088bb0b009999000440044000000000000000000000000000000000
ddd0000000000000d000000000000000d000000000000000000000000000000007788760087e88b0099999904474447400000000000000000000000000000000
d66ddd0000000000ddd0000000000000dd0000000000000000000000000000007f777ff70788bb8b99bbbb994492449200000000000000000000000000000000
d67666ddddddd000d67ddd0000000000dddd00000000000000000000000000007ffff447e98ebb8b9b4b88b94442444200000000000000000000000000000000
0d7777666666d0000d7766ddddddd0000d77ddd000ddd00000511680000ddd000744447088898888b444888b4442444200000000000000000000000000000000
0d677777777d00000d677766776d00000d67776ddddd0000000511000051178000722600888888424aaaaaa44444444400000000000000000000000000000000
00dd67776dd0000000dd67776dd0000000dd67776dd0000000000000005112000007600089888420aaaaaaaa0550055000000000000000000000000000000000
0000ddddd00000000000ddddd00000000000ddddd000000000000000000000000077760008842000999999990ff00ff000000000000000000000000000000000
000000000000000000000000000000000ee0ee000000e00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0077770000cccc00000cc00000777700e7feeee000088e0000000000000000000000000000000000000000000000000000000000000000000000000000000000
077777700c7777c000c77c00077cc770efeeee800008880000000000000000000000000000000000000000000000000000000000000000000000000000000000
077777700c7777c00c7777c007cccc700eeee820008224e000000000000000000000000000000000000000000000000000000000000000000000000000000000
077777700c7777c00c7777c007cccc7000ee820000066f0000000000000000000000000000000000000000000000000000000000000000000000000000000000
077777700c7777c000c77c00077cc770000820000006f70000000000000000000000c00000c000c0000000000000000000000000000000000000000000000000
0077770000cccc00000cc00000777700000000000006f700000000000000c0000000c00000cc0cc000c000c00000000000000000000000000000000000000000
00000000000000000000000000000000000000000006f700000000000000c000000ccc000000d0000c00000c0c00000c00000000000000000000000000000000
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
00000000e000000000000000e000000000000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000eee00000000000000e000000000000000e000000000000000000000000000000000000000000007000000000000070000000000000000070000070000
00000eeeeeee00000000000eee0000000000000eee0000000000000000000e000000000000000000000000000000007000000000000070000070000000000000
0000efe171eee000000c00e676e000000000000eee000000000000000000e0000000000000000000000c000c0000000000000c000c000000000000000c000c00
000efe77777efe00000000e171e00c0000c0000e6e00000000000000000e200000000000000000000000c7c0000a0000000000c7a000000000000a0000c7c000
000eee67776eee0000000e67776e000000000001710000c00000000000ee000000007000000700000700777000a7a0000000007a7a0000000000a7a000777000
00eeeeeeeeeeeee000000eeeeeee000000000006e6000000000000000ee2000000000000007770000000c7c00a777a00000000a777a00000000a777a00c7c000
00eeee22222eeee00000eee222eee000000000eeeee0000000000000eee000000000000000070000000c000c00a7a00000700c0a7a0000000000a7a00c000c00
00e2e2222222e2e00000ee22222ee000000000eeeee000000000000eee200000000000000000000000000000000a000000000000a000070000000a0000000000
00e22222e22222e0000ee222e222ee00000000eeeee00000000000eeee00000000000000000000000000000000000000c0000000000000000000000000070000
00e22222e22222e0000e2222e2222e00000000e2e2e0000000000eeee2000000c0000000000000000c0000000000007000000000000000000000000000000000
00200200e0020020000e0200e0020e0000000002e2000000000e00eee000000000e000000000000000e000000000000000e000000000000000e0000000000000
00000000e000000000000000e000000000000000e000000000e000e0200000000e00eeeeeef000000e00feeeeef000000e00eeeffe0000000e00feeeeef00000
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
00eee00eeede0deeed0eee0e0eeeed0eeed00eee0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4142434440464748414243444046474800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000045000000000000004500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
001a071f0161105611096110f611126111361114611146111361112611116110f6110f6111061113611146111561117611176111761116611136111261111611116111061110611116111461117611196111a611
010600000e0751077513075187751a0751c7751f07524775126000e60013600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000097010b7010d7010e7010f70110701117011170111700107000f7000e7000c7000a700087000770006700057000470003700027000170001700017000170001700017000170001700017000170001700
0004000035663290531b6531b0531b0531264312043120430863308033080331f0030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0106000018064240641a054260541c044280441d034290341f0242b02408003017000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200000e7710e7710e7710e7710e7710e7710e7710e7710c7710c7710a7710a7710877108771077710777105771057710476104761037510375101741017410173101731017210172101711017110171101711
01060000240012400124003240031f0031b00317003120030e0030b00307003040030100301003010030100301003010030100301003010030000000000000000000000000000000000000000000000000000000
010a0000110631d063230002300002000010040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000e7211a7411f7611f7411f00021000230001f000280003700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102000002770006030c6100c61018620186201862018620186201862024610246100000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a0000307402d7401f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a00001154021540245401500020503000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800001c5601f560245602455024540245302452500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001c1011c1011a1001a1001810018100016001c0001c0001c0001c0001c0001c0001c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011600001075513755177551375510755137551775513755107551375517755137551075513755177551375510755137551775513755107551375517755137551075513755177551375510755137551775513755
011600000c7551075513755107550c7551075513755107550c7551075513755107550c7551075513755107550c7551075513755107550c7551075513755107550c7551075513755107550c755107551375510755
001000000e0051070513005187051a0051c7051f005247050f0001200014000160000e0001000011000130000c00013700100000e7000c0000000000000000000000000000000000000000000000000000000000
001000000260302604026010260102601026010260102601026050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001060410604106041060410600136001360013600196001b6001e6002360028600326003a6003e6003c6053960535605316052d605266052060519605126050e6050b6050760505606046060460604606
001000000000000000077000000000000287000000037700000001a70000000307000c00000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011600000042500415094250a4250042500415094250a42500425094253f2050a42508425094250a425074250c4250a42503425004150c4250a42503425004150c42500415186150042502425024250342504425
011600000c0330c4130f54510545186150c0330f545105450c0330f5450c41310545115450f545105450c0230c0330c4131554516545186150c03315545165450c0330c5450f4130f4130e5450e5450f54510545
0116000005425054150e4250f42505425054150e4250f425054250e4253f2050f4250d4250e4250f4250c4250a4250a42513425144150a4250a42513425144150a42509415086150741007410074120441101411
011600000c0330c4131454515545186150c03314545155450c033145450c413155451654514545155450c0230c0330c413195451a545186150c033195451a5451a520195201852017522175220c033186150c033
010b00200c03324510245102451024512245122751127510186151841516215184150c0031841516215134150c033114151321516415182151b4151d215224151861524415222151e4151d2151c4151b21518415
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

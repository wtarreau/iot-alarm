-- alarm clock application
-- only works with a stripped down firmware (integer, 12 modules)

-- transition delays in milliseconds
LIGHT_FULL_TIME=30000
LIGHT_STAY_TIME=1800000
LIGHT_STOP_TIME=30000

-- light states
LS_IDLE=0
LS_FULL_START=1
LS_FULL=2
LS_FULL_STOP=3

-- current light state (public)
light_state=LS_IDLE

-- current time
tyy,tmm,tdd,th,tm,ts,twd=0,0,0,0,0,0,0

-- basic alarm time, number of minutes of the day, -1=off
alarm=-1

-- last change date
local light_change=0
local light_bright=0

-- screens
local curr_screen=nil -- set to nil to force an immediate refresh on want_screen
local want_screen=0

-- debounced button states (0=pressed,1=released), time counts, and callbacks.
-- Callbacks : function(btn,0/1/2/3/4) for release/press/long/repeat/stop.
-- Note: "stop" is sent instead of "release" after "repeat"/"long" so that
-- "release" is a release after a short press only. "long" is handled by a
-- timer and automatically repeats every 200ms with the "repeat" event.
-- btn_cnt is 0 on release and starts at 1 when pressed, and caps to 5 (1 sec).
-- It's enough to detect a press. It uses timer #2.
local btn_state={1,1}
local btn_cnt={0,0}

-- this are the callbacks to set from outside
local btn_cb={}

-- functions to set the various screens
local screen_set={}

-- low level button handlers
local function btn_trig(btn,lev)
  local ev
  if btn_state[btn] ~= lev then
    btn_state[btn] = lev
    if lev == 1 then
      ev=btn_cnt[btn] < 5 and 0 or 4
      btn_cnt[btn]=0
    elseif lev == 0 and btn_cnt[btn] == 0 then
      ev=1
      btn_cnt[btn]=1
    end
    if ev ~= nil and btn_cb[btn] ~= nil then
      btn_cb[btn](btn, ev)
    end
  end
end

-- return the time spent in the current state in ms except idle (always 0)
local function light_duration()
  local now=tmr.now()
  if light_state == LS_IDLE then return 0 end
  now=now-light_change
  if now < 0 then now=now+1073741824 now=now+1073741824 end
  return math.floor(now / 1000)
end

local function light_set_state(state)
  light_change=tmr.now()
  light_state=state
end

-- return the new brightness based on the time spent in the state (0..1023) and
-- adjust transient states.
local function light_new_brightness()
  local dur=light_duration()

  if light_state == LS_FULL_START then
    if dur < LIGHT_FULL_TIME then return math.floor(light_duration() * 1023 / LIGHT_FULL_TIME) end
    light_set_state(LS_FULL)
  end

  if light_state == LS_FULL then
     if dur < LIGHT_STAY_TIME then return 1023 end
     light_set_state(LS_FULL_STOP)
  end

  if light_state == LS_FULL_STOP then
    if dur < LIGHT_FULL_TIME then return 1023 - math.floor(light_duration() * 1023 / LIGHT_FULL_TIME) end
     light_set_state(LS_IDLE)
  end

  return 0
end

-- set light's pwm from 0 to 1023 (quadratic curve)
local function light_pwm(val)
  val=val < 0 and 0 or val > 1023 and 1023 or val
  val=val*val/1023
  pwm.setduty(brd_pwm, val)
end

-- returns alarm hour, or -1 if off
local function alarm_h()
  return alarm >= 0 and math.floor(alarm/60) or -1
end

-- returns alarm minute, or -1 if off
local function alarm_m()
  return alarm >= 0 and alarm%60 or -1
end


-- screen0 displays the current time and the day of week
local function screen0_show()
  disp_7seg_str(0,0,string.format("%d  %02d%s%02d",twd,th,(ts%2==0) and ":" or " ",tm))
end

local function screen0_btn1_cb(btn,ev)
  if ev == 0 then return end

  if light_state == LS_IDLE then
    light_set_state(LS_FULL_START)
  elseif light_state < 6 then
    light_set_state(light_state+1)
  else
    light_set_state(LS_IDLE)
  end
  if ev == 1 or ev == 4 then curr_screen=nil end
end

local function screen0_btn2_cb(btn,ev)
  if ev == 0 then want_screen=1 end
  if ev == 2 then want_screen=2 end
end

local function screen0_unload()
  local G=getfenv()
  G.screen_show=nil
  G.screen_unload=nil
  btn_cb[1]=nil
  btn_cb[2]=nil
end

local function screen0_set()
  local G=getfenv()
  G.screen_show=screen0_show
  G.screen_unload=screen0_unload
  btn_cb[1]=screen0_btn1_cb
  btn_cb[2]=screen0_btn2_cb
end

if screen_set then
  screen_set[0]=screen0_set
end


-- screen1 displays current date, time, alarm and state. Uses the t* time variables
local function screen1_show()
  disp_lines(string.format("%04d-%02d-%02d (%d)",tyy,tmm,tdd,twd),
             string.format("%02d:%02d:%02d   [al %02d:%02d]",th,tm,ts,alarm_h(),alarm_m()),
             string.format("state=%d ratio=%d",light_state, light_bright))
end

local function screen1_btn1_cb(btn,ev)
  if ev == 0 then return end

  if light_state == LS_IDLE then
    light_set_state(LS_FULL_START)
  elseif light_state < 6 then
    light_set_state(light_state+1)
  else
    light_set_state(LS_IDLE)
  end
  if ev == 1 or ev == 4 then screen1_show() end
end

local function screen1_btn2_cb(btn,ev)
  if ev == 0 then want_screen=0 end
  if ev == 2 then want_screen=2 end
end

local function screen1_unload()
  local G=getfenv()
  G.screen_show=nil
  G.screen_unload=nil
  btn_cb[1]=nil
  btn_cb[2]=nil
end

local function screen1_set()
  local G=getfenv()
  G.screen_show=screen1_show
  G.screen_unload=screen1_unload
  btn_cb[1]=screen1_btn1_cb
  btn_cb[2]=screen1_btn2_cb
end

if screen_set then
  screen_set[1]=screen1_set
end


-- screen2 displays the alarm time
local digit=1

local function screen2_show()
  disp_7seg_str(0,0,string.format("%02d:%02d",alarm_h(),alarm_m()),digit)
end

local function screen2_btn1_cb(btn,ev)
  local ah,am=alarm_h(),alarm_m()
  if ev == 0 then return end
  if ev == 4 then screen2_show() return end

  if ah < 0 or am < 0 then ah=0 am=0
  elseif digit == 1 then   ah=ah+10
  elseif digit == 2 then   ah=ah+1
  elseif digit == 4 then   am=am+10
  elseif digit == 5 then   am=am+1
  end

  if ah > 23 then ah=-1 end
  if am > 59 then am=0 end
  alarm=(ah >= 0) and ah*60+am or -1

  if ev == 1 then screen2_show() end
end

local function screen2_btn2_cb(btn,ev)
  if ev == 0 then
    digit=(digit >= 5) and 1 or (digit==2) and 4 or (digit+1)
    screen2_show()
  end
  if ev == 2 then want_screen=0 end
end

local function screen2_unload()
  local G=getfenv()
  G.screen_show=nil
  G.screen_unload=nil
  btn_cb[1]=nil
  btn_cb[2]=nil
end

local function screen2_set()
  local G=getfenv()
  G.screen_show=screen2_show
  G.screen_unload=screen2_unload
  btn_cb[1]=screen2_btn1_cb
  btn_cb[2]=screen2_btn2_cb
end

if screen_set then
  screen_set[2]=screen2_set
end


-- manages screen and brightness
local function refresh()
  local ratio=light_new_brightness()
  local yy,mm,dd,h,m,s,wd=time_get_now()
  local force_refresh

  if m ~= tm then force_refresh=1 end

  if s ~= nil then
    tyy,tmm,tdd,th,tm,ts,twd=yy,mm,dd,h,m,s,wd
    yy,mm,dd,h,m,s,wd=nil,nil,nil,nil,nil,nil,nil
  end

  if curr_screen ~= want_screen then
    if screen_unload ~= nil then screen_unload() end
    curr_screen=want_screen
    if screen_set[curr_screen] then screen_set[curr_screen]() end
    force_refresh=1
  end

  if ratio ~= light_bright then
    light_bright=ratio
    light_pwm(ratio)
  end

  if screen_show ~= nil and force_refresh then
    screen_show()
  end
end

-- timer handler for button time measurement
local function auto_repeat()
  local btn
  for btn=1,2 do
    if btn_cnt[btn] == 5 then
      if btn_cb[btn] ~= nil then btn_cb[btn](btn,3) end
    elseif btn_cnt[btn] > 0 then
      btn_cnt[btn]=btn_cnt[btn]+1
      if btn_cnt[btn] == 5 and btn_cb[btn] ~= nil then btn_cb[btn](btn,2) end
    end
  end
end

-- periodic callback
local function tick()
  if light_state == LS_IDLE and th == alarm_h() and tm == alarm_m() then
    light_set_state(LS_FULL_START)
  end
  refresh()
end



-- main entry point

pwm.setup(brd_pwm,500,0)
pwm.start(brd_pwm)

if brd_btn1 and debounce then
  gpio.trig(brd_btn1,"both",function()
    btn_trig(1,debounce(brd_btn1))
  end)
end

if brd_btn2 and debounce then
  gpio.trig(brd_btn2,"both",function()
    btn_trig(2,debounce(brd_btn2))
  end)
end

local tmr_refresh = tmr.create()
tmr_refresh:alarm(100,tmr.ALARM_AUTO,tick)

local btn_tmr = tmr.create()
btn_tmr:alarm(200,tmr.ALARM_AUTO,auto_repeat)
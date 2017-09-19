-- alarm clock application

-- debounced button states
btn1_state=1
btn2_state=1

-- light states
LS_IDLE=0
LS_FULL_START=1
LS_FULL=2
LS_FULL_STOP=3
LS_HALF_START=4
LS_HALF=5
LS_HALF_STOP=6

-- transition delays in milliseconds
LIGHT_FULL_TIME=30000
LIGHT_STAY_TIME=1800000
LIGHT_HALF_TIME=15000
LIGHT_STOP_TIME=30000

-- light state, last change date, last brightness
light_state=LS_IDLE
light_change=0
light_bright=0
force_refresh=nil

-- current time
tyy,tmm,tdd,th,tm,ts,twd=0,0,0,0,0,0,0

-- basic alarm time, number of minutes of the day, -1=off
alarm=-1

-- low level button handlers
function btn1_trig()
  local lev=debounce(brd_btn1)
  if btn1_state ~= lev then
    btn1_state = lev
    btn1_cb()
  end
end

function btn2_trig()
  local lev=debounce(brd_btn2)
  if btn2_state ~= lev then
    btn2_state = lev
    btn2_cb()
  end
end

-- return the time spent in the current state in ms except idle (always 0)
function light_duration()
  local now=tmr.now()
  if light_state == LS_IDLE then return 0 end
  now=now-light_change
  if now < 0 then now=now+2147483648 end
  return math.floor(now / 1000)
end

function light_set_state(state)
  light_change=tmr.now()
  light_state=state
end

-- return the new brightness based on the time spent in the state (0..1023) and
-- adjust transient states.
function light_new_brightness()
  local dur=light_duration()

  if light_state == LS_FULL_START then
    if dur < LIGHT_FULL_TIME then return math.floor(light_duration() * 1023 / LIGHT_FULL_TIME) end
    light_set_state(LS_FULL)
  end

  if light_state == LS_HALF_START then
    if dur < LIGHT_HALF_TIME then return math.floor(light_duration() * 512 / LIGHT_HALF_TIME) end
    light_set_state(LS_HALF)
  end

  if light_state == LS_FULL then
     if dur < LIGHT_STAY_TIME then return 1023 end
     light_set_state(LS_FULL_STOP)
  end

  if light_state == LS_HALF then
     if dur < LIGHT_STAY_TIME then return 512 end
     light_set_state(LS_HALF_STOP)
  end

  if light_state == LS_FULL_STOP then
    if dur < LIGHT_FULL_TIME then return 1023 - math.floor(light_duration() * 1023 / LIGHT_FULL_TIME) end
     light_set_state(LS_IDLE)
  end

  if light_state == LS_HALF_STOP then
    if dur < LIGHT_HALF_TIME then return 512 - math.floor(light_duration() * 512 / LIGHT_HALF_TIME) end
     light_set_state(LS_IDLE)
  end

  return 0
end


-- set light's pwm from 0 to 1023 (quadratic curve)
function light_pwm(val)
  val=val < 0 and 0 or val > 1023 and 1023 or val
  val=val*val/1023
  pwm.setduty(brd_pwm, val)
end

-- returns alarm hour, or -1 if off
function alarm_h()
  return alarm >= 0 and math.floor(alarm/60) or -1
end

-- returns alarm minute, or -1 if off
function alarm_m()
  return alarm >= 0 and alarm%60 or -1
end

-- manages screen and brightness
function refresh()
  local ratio=light_new_brightness()
  local yy,mm,dd,h,m,s,wd=time_get_now()

  if m ~= nil and (m ~= tm or force_refresh) then
    force_refresh=nil
    tyy,tmm,tdd,th,tm,ts,twd=yy,mm,dd,h,m,s,wd
    disp_lines(string.format("%04d-%02d-%02d (%d)",yy,mm,dd,wd),
               string.format("%02d:%02d:%02d   [al %02d:%02d]",h,m,s,alarm_h(),alarm_m()),
	       string.format("state=%d ratio=%d",light_state, ratio))
  end

  if ratio ~= light_bright then
    light_bright=ratio
    light_pwm(ratio)
  end
end

-- high level button functions, debounced
function btn1_cb()
  print("btn1: ",btn1_state," st: ",light_state)
  if btn1_state == 1 then return end

  if btn2_state == 0 then
    -- disable alarm if btn1 pressed while btn2 pressed.
    alarm=-1
  else
    if light_state == LS_IDLE then
      light_set_state(LS_FULL_START)
    elseif light_state < 6 then
      light_set_state(light_state+1)
    else
      light_set_state(LS_IDLE)
    end
  end
  force_refresh=1
  refresh()
  print("    new st: ",light_state)
end

function btn2_cb()
  if btn2_state == 1 then return end
  alarm = alarm < 0 and 0 or alarm >= 1410 and -1 or (alarm + 30)
  print("btn2: alarm: ",alarm_h(),":",alarm_m())
  force_refresh=1
  refresh()
end

-- periodic callback
function tick()
  if light_state == LS_IDLE and th == alarm_h() and tm == alarm_m() then
    light_state = LS_FULL_START
  end
  refresh()
end

-- entry point

gpio.trig(brd_btn1,"both",btn1_trig)
gpio.trig(brd_btn2,"both",btn2_trig)
pwm.setup(brd_pwm,500,0)
pwm.start(brd_pwm)
tmr.alarm(1,100,tmr.ALARM_AUTO,tick)

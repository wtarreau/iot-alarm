-- alarm clock application
-- only works with a stripped down firmware (integer, 12 modules)

function load_files(...)
  local arg={...}
  local f
  for f=1,#arg do
    if file.exists(arg[f] .. ".lc") then dofile(arg[f] .. ".lc")
    elseif file.exists(arg[f] .. ".lua") then dofile(arg[f] .. ".lua")
    else print("Missing file " .. arg[f])
    end
  end
end

load_files("alarm-vars","alarm-buttons","alarm-light")

-- a few local variables
force_refresh=nil
light_bright=0

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

  if m ~= nil and (m ~= tm or force_refresh) and disp_lines ~= nil then
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
function btn1_cb(btn,ev)
  print("btn:",btn,": ev=",ev)
  if ev == 0 then return end

  if btn_state[2] == 0 then
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
  if ev ~= 2 then
    force_refresh=1
    refresh()
  end
end

function btn2_cb(btn,ev)
  print("btn:",btn,": ev=",ev)
  if ev == 1 then return end
  alarm = alarm < 0 and 0 or alarm >= 1410 and -1 or (alarm + 30)
  print("btn2: alarm: ",alarm_h(),":",alarm_m())
  if ev ~= 2 then
    force_refresh=1
    refresh()
  end
end

-- periodic callback
function tick()
  if light_state == LS_IDLE and th == alarm_h() and tm == alarm_m() then
    light_state = LS_FULL_START
  end
  refresh()
end

-- entry point

tmr.alarm(1,100,tmr.ALARM_AUTO,tick)
btn_cb[1]=btn1_cb
btn_cb[2]=btn2_cb
